import { Controller } from '@hotwired/stimulus'
import { renderStreamMessage } from '@hotwired/turbo'

const PREFETCH_ROOT_MARGIN = '400px 0px'
const PREFETCH_MARGIN_PX = 400
const SCROLL_EDGE_PX = 800
const MAX_FILL_ROUNDS = 24
const MAX_CHAIN_AFTER = 8
const MAX_CHAIN_BEFORE = 8
const MAX_DUPE_SKIPS = 5
const MAX_TRANSIENT_RETRIES = 3
const RETRY_BASE_MS = 400
const DEFERRED_CONTINUE_MS = 250
const BACK_TO_TOP_SHOW_PX = 800
const MIN_ROWS = 8
const MAX_ROWS = 20
const ROW_HEIGHT_FALLBACK = 280
const BUFFER_ROWS = 4

type StatusMode = 'idle' | 'loading' | 'error' | 'end'
type FetchDirection = 'after' | 'before'

/**
 * Bidirectional row-window infinite scroll for a card grid.
 *
 * CSS owns layout (card-sized auto-fill). This controller keeps a sliding
 * window of cols×rows cards: scroll down appends one row and drops one from
 * the top; scroll up prepends one row and drops one from the bottom.
 * End-of-list only when the window covers the true end of the result set.
 *
 * Fetch URLs are built from window.location (client owns query params).
 * Sentinels expose has-more flags, total-count, and offset only.
 */
export default class extends Controller {
  static targets = ['sentinel', 'topSentinel', 'status', 'backToTop', 'grid']
  static values = {
    perPage: { type: Number, default: 48 },
    sentinelId: { type: String, default: 'models-scroll-sentinel' },
    topSentinelId: { type: String, default: 'models-scroll-sentinel-top' },
    cardSelector: { type: String, default: '.model-card' },
    storageKeyPrefix: { type: String, default: 'scroll_models_' },
    totalCount: { type: Number, default: 0 },
    windowStart: { type: Number, default: 0 },
    endMessage: { type: String, default: '' },
    errorMessage: { type: String, default: '' },
    loadingMessage: { type: String, default: '' }
  }

  declare perPageValue: number
  declare sentinelIdValue: string
  declare topSentinelIdValue: string
  declare cardSelectorValue: string
  declare storageKeyPrefixValue: string
  declare totalCountValue: number
  declare windowStartValue: number
  declare endMessageValue: string
  declare errorMessageValue: string
  declare loadingMessageValue: string
  declare sentinelTarget: HTMLElement
  declare hasSentinelTarget: boolean
  declare topSentinelTarget: HTMLElement
  declare hasTopSentinelTarget: boolean
  declare statusTarget: HTMLElement
  declare hasStatusTarget: boolean
  declare backToTopTarget: HTMLElement
  declare hasBackToTopTarget: boolean
  declare gridTarget: HTMLElement
  declare hasGridTarget: boolean

  private loading = false
  private mutating = false
  private hasMoreAfter = true
  private hasMoreBefore = false
  private cols = 1
  private rows = MIN_ROWS
  private windowSize = MIN_ROWS
  private cachedColumns: number | null = null
  private observer: IntersectionObserver | null = null
  private resizeObserver: ResizeObserver | null = null
  private mutationObserver: MutationObserver | null = null
  private boundOnScroll: () => void
  private boundOnBeforeVisit: () => void
  private boundOnBackToTop: (e: Event) => void
  private scrollTicking = false
  private abortController: AbortController | null = null
  private restoredScroll = false
  private refillQueued = false
  private chainAfterQueued = false
  private chainBeforeQueued = false
  private chainAfterDepth = 0
  private chainBeforeDepth = 0
  private consecutiveDupeSkips = 0
  /** Absolute index into the full result set for the next after-fetch. Independent of windowStart. */
  private afterFetchCursor = 0
  private statusMode: StatusMode = 'idle'
  private deferredAfterTimer: number | null = null
  private deferredBeforeTimer: number | null = null

  connect (): void {
    this.boundOnScroll = this.onScroll.bind(this)
    this.boundOnBeforeVisit = this.onBeforeVisit.bind(this)
    this.boundOnBackToTop = this.onBackToTop.bind(this)
    window.addEventListener('scroll', this.boundOnScroll, { passive: true })
    document.addEventListener('turbo:before-visit', this.boundOnBeforeVisit)
    if (this.hasBackToTopTarget) {
      this.backToTopTarget.addEventListener('click', this.boundOnBackToTop)
    }

    this.stripPageFromUrl()
    this.syncMetaFromSentinels()
    this.recomputeWindowSize()
    this.afterFetchCursor = this.windowStartValue + this.cards().length
    this.refreshBounds()
    this.setupObserver()
    this.setupResizeObserver()
    this.setupMutationObserver()
    this.setStatusMode('idle')
    this.updateBackToTop()
    this.updateExhaustionUi()
    void this.bootstrap()
  }

  disconnect (): void {
    window.removeEventListener('scroll', this.boundOnScroll)
    document.removeEventListener('turbo:before-visit', this.boundOnBeforeVisit)
    if (this.hasBackToTopTarget) {
      this.backToTopTarget.removeEventListener('click', this.boundOnBackToTop)
    }
    this.observer?.disconnect()
    this.observer = null
    this.resizeObserver?.disconnect()
    this.resizeObserver = null
    this.mutationObserver?.disconnect()
    this.mutationObserver = null
    this.clearDeferredContinues()
    this.abortInFlight()
  }

  sentinelTargetConnected (): void {
    this.syncMetaFromSentinels()
    this.refreshBounds()
    this.setupObserver()
    this.updateExhaustionUi()
  }

  topSentinelTargetConnected (): void {
    this.syncMetaFromSentinels()
    this.refreshBounds()
    this.setupObserver()
  }

  private abortInFlight (): void {
    if (this.abortController != null) {
      this.abortController.abort()
      this.abortController = null
    }
  }

  private clearDeferredContinues (): void {
    if (this.deferredAfterTimer != null) {
      window.clearTimeout(this.deferredAfterTimer)
      this.deferredAfterTimer = null
    }
    if (this.deferredBeforeTimer != null) {
      window.clearTimeout(this.deferredBeforeTimer)
      this.deferredBeforeTimer = null
    }
  }

  private async bootstrap (): Promise<void> {
    await this.fillOrTrimWindow()
    this.restoreScrollIfNeeded()
    this.updateExhaustionUi()
  }

  private setupResizeObserver (): void {
    this.resizeObserver?.disconnect()
    if (typeof ResizeObserver === 'undefined') return
    this.resizeObserver = new ResizeObserver(() => {
      this.cachedColumns = null
      const prevSize = this.windowSize
      this.recomputeWindowSize()
      this.setupObserver()
      if (this.windowSize !== prevSize) {
        void this.fillOrTrimWindow()
        return
      }
      this.maybeContinueAfter()
      this.maybeContinueBefore()
    })
    this.resizeObserver.observe(this.gridEl())
  }

  private setupMutationObserver (): void {
    this.mutationObserver?.disconnect()
    if (typeof MutationObserver === 'undefined') return
    this.mutationObserver = new MutationObserver((records) => {
      if (this.mutating || this.loading) return
      let removedCard = false
      for (const record of records) {
        record.removedNodes.forEach((node) => {
          if (!(node instanceof HTMLElement)) return
          if (node.matches?.(this.cardSelectorValue) || node.querySelector?.(this.cardSelectorValue)) {
            removedCard = true
          }
        })
      }
      if (removedCard) {
        this.queueRefill()
      }
    })
    this.mutationObserver.observe(this.gridEl(), { childList: true, subtree: false })
  }

  private queueRefill (): void {
    if (this.refillQueued) return
    this.refillQueued = true
    requestAnimationFrame(() => {
      this.refillQueued = false
      void this.refillOneAfterDelete()
    })
  }

  private setupObserver (): void {
    this.observer?.disconnect()
    this.observer = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          if (!entry.isIntersecting) continue
          const el = entry.target as HTMLElement
          if (el.id === this.sentinelIdValue || el === this.bottomSentinelEl()) {
            void this.fetchRow('after')
          } else if (el.id === this.topSentinelIdValue || el === this.topSentinelEl()) {
            void this.fetchRow('before')
          }
        }
      },
      { root: null, rootMargin: PREFETCH_ROOT_MARGIN, threshold: 0 }
    )
    const bottom = this.bottomSentinelEl()
    const top = this.topSentinelEl()
    if (bottom != null && this.hasMoreAfter) this.observer.observe(bottom)
    if (top != null && this.hasMoreBefore) this.observer.observe(top)
  }

  private bottomSentinelEl (): HTMLElement | null {
    return document.getElementById(this.sentinelIdValue)
  }

  private topSentinelEl (): HTMLElement | null {
    return document.getElementById(this.topSentinelIdValue)
  }

  private syncMetaFromSentinels (): void {
    const bottom = this.bottomSentinelEl()
    const top = this.topSentinelEl()
    const el = bottom ?? top
    if (el == null) return

    const totalRaw = el.dataset.totalCount
    if (totalRaw != null && totalRaw.length > 0) {
      const total = parseInt(totalRaw, 10)
      if (Number.isFinite(total) && total >= 0) {
        this.totalCountValue = total
      }
    }
  }

  private refreshBounds (): void {
    const count = this.cards().length
    if (this.totalCountValue > 0) {
      this.hasMoreAfter = this.windowStartValue + count < this.totalCountValue
      this.hasMoreBefore = this.windowStartValue > 0
    } else {
      const bottom = this.bottomSentinelEl()
      const top = this.topSentinelEl()
      this.hasMoreAfter = bottom?.dataset.hasMoreAfter === 'true'
      this.hasMoreBefore = this.windowStartValue > 0 || top?.dataset.hasMoreBefore === 'true'
    }
  }

  private cards (): HTMLElement[] {
    const selector = this.cardSelectorValue !== '' ? this.cardSelectorValue : '.model-card'
    return Array.from(this.gridEl().querySelectorAll<HTMLElement>(`:scope > ${selector}`))
  }

  private measureColumns (): number {
    if (this.cachedColumns != null && this.cachedColumns > 0) {
      return this.cachedColumns
    }
    const cards = this.cards()
    if (cards.length === 0) {
      this.cachedColumns = 1
      return 1
    }
    const y0 = cards[0].offsetTop
    let cols = 0
    for (const card of cards) {
      if (card.offsetTop !== y0) break
      cols += 1
    }
    this.cachedColumns = Math.max(1, cols)
    return this.cachedColumns
  }

  private measureRows (): number {
    const cards = this.cards()
    let rowHeight = ROW_HEIGHT_FALLBACK
    if (cards.length > 0) {
      const first = cards[0]
      const gap = this.readGap()
      rowHeight = Math.max(80, first.offsetHeight + gap)
    }
    const viewportRows = Math.ceil(window.innerHeight / rowHeight) + BUFFER_ROWS
    return Math.min(MAX_ROWS, Math.max(MIN_ROWS, viewportRows))
  }

  private readGap (): number {
    const style = getComputedStyle(this.gridEl())
    const gap = parseFloat(style.rowGap !== '' ? style.rowGap : (style.gap !== '' ? style.gap : '0'))
    return Number.isFinite(gap) ? gap : 0
  }

  private recomputeWindowSize (): void {
    this.cols = this.measureColumns()
    this.rows = this.measureRows()
    this.windowSize = this.cols * this.rows
    this.perPageValue = this.cols
  }

  private async fillOrTrimWindow (): Promise<void> {
    this.recomputeWindowSize()
    this.refreshBounds()

    let cards = this.cards()
    if (cards.length > this.windowSize) {
      this.trimBottomToWindow()
      cards = this.cards()
    }

    let guard = 0
    while (
      guard < MAX_FILL_ROUNDS &&
      this.cards().length < this.windowSize &&
      this.hasMoreAfter
    ) {
      guard += 1
      const need = this.windowSize - this.cards().length
      const limit = Math.ceil(need / this.cols) * this.cols
      const ok = await this.fetchCards(limit, 'after')
      if (!ok) break
      this.refreshBounds()
    }

    if (this.cards().length > this.windowSize) {
      this.trimBottomToWindow()
    }

    this.setupObserver()
    this.updateExhaustionUi()
  }

  private trimBottomToWindow (): void {
    const excess = this.cards().length - this.windowSize
    if (excess <= 0) return
    const rowsToDrop = Math.floor(excess / this.cols)
    if (rowsToDrop < 1) return
    this.dropRows('bottom', rowsToDrop)
    this.afterFetchCursor = this.windowStartValue + this.cards().length
    this.refreshBounds()
  }

  /**
   * After append/prepend, keep at most windowSize cards by dropping complete
   * rows from the opposite end.
   */
  private maintainWindow (direction: FetchDirection): void {
    const excess = this.cards().length - this.windowSize
    if (excess <= 0) return
    const rowsToDrop = Math.floor(excess / this.cols)
    if (rowsToDrop < 1) return

    if (direction === 'after') {
      this.dropRows('top', rowsToDrop)
      this.windowStartValue += rowsToDrop * this.cols
    } else {
      this.dropRows('bottom', rowsToDrop)
      this.afterFetchCursor = this.windowStartValue + this.cards().length
    }
    this.refreshBounds()
  }

  private dropRows (side: 'top' | 'bottom', rowCount: number): void {
    const cols = this.cols
    const removeCount = rowCount * cols
    if (removeCount < 1) return

    const cards = this.cards()
    if (cards.length < removeCount) return

    const slice = side === 'top'
      ? cards.slice(0, removeCount)
      : cards.slice(cards.length - removeCount)

    let height = 0
    if (side === 'top' && slice.length > 0) {
      const first = slice[0]
      const last = slice[slice.length - 1]
      const top = first.getBoundingClientRect().top + window.scrollY
      const bottom = last.getBoundingClientRect().bottom + window.scrollY
      height = Math.max(0, bottom - top)
    }

    this.mutating = true
    try {
      const scrollY = window.scrollY
      for (const card of slice) {
        card.remove()
      }
      if (side === 'top' && height > 0) {
        window.scrollTo(0, Math.max(0, scrollY - height))
      }
    } finally {
      this.mutating = false
    }
  }

  /** Client owns fetch URLs — clone current location and set offset/per_page/window. */
  private buildFetchUrl (offset: number, limit: number, windowDir: FetchDirection): string {
    const url = new URL(window.location.href)
    url.searchParams.delete('page')
    url.searchParams.set('offset', String(Math.max(0, offset)))
    url.searchParams.set('per_page', String(Math.max(1, limit)))
    url.searchParams.set('window', windowDir)
    return url.pathname + url.search
  }

  private async fetchRow (direction: FetchDirection): Promise<boolean> {
    this.recomputeWindowSize()
    this.refreshBounds()

    if (direction === 'after') {
      if (!this.hasMoreAfter) {
        this.updateExhaustionUi()
        return false
      }
      return await this.fetchCards(this.cols, 'after')
    }

    if (!this.hasMoreBefore || this.windowStartValue <= 0) {
      return false
    }
    const limit = Math.min(this.cols, this.windowStartValue)
    return await this.fetchCards(limit, 'before')
  }

  private async refillOneAfterDelete (): Promise<void> {
    this.refreshBounds()
    if (!this.hasMoreAfter || this.loading) return
    if (this.cards().length >= this.windowSize) return
    await this.fetchCards(1, 'after')
    this.updateExhaustionUi()
  }

  private async fetchCards (limit: number, direction: FetchDirection): Promise<boolean> {
    if (this.loading) return false

    const offset = direction === 'after'
      ? this.afterFetchCursor
      : Math.max(0, this.windowStartValue - limit)

    if (direction === 'before' && this.windowStartValue <= 0) return false
    if (direction === 'after' && this.totalCountValue > 0 && offset >= this.totalCountValue) {
      this.hasMoreAfter = false
      this.updateExhaustionUi()
      return false
    }

    const url = this.buildFetchUrl(offset, limit, direction)

    this.loading = true
    this.setLoadingUi(true, direction)

    const anchor = direction === 'before' ? this.cards()[0] : null
    const anchorTop = anchor?.getBoundingClientRect().top ?? 0
    let shouldContinueAfter = false
    let shouldContinueBefore = false

    try {
      for (let attempt = 0; attempt <= MAX_TRANSIENT_RETRIES; attempt++) {
        this.abortController = new AbortController()

        try {
          const response = await fetch(url, {
            headers: {
              Accept: 'text/vnd.turbo-stream.html',
              'X-Infinite-Scroll': '1'
            },
            credentials: 'same-origin',
            signal: this.abortController.signal
          })

          if (!response.ok) {
            console.warn('[infinite-scroll] HTTP', response.status, url)
            if (response.status === 401 || response.status === 403 || response.status === 404) {
              this.applyAuthFailure(direction)
              return false
            }
            if (attempt < MAX_TRANSIENT_RETRIES) {
              await this.delay(RETRY_BASE_MS * (attempt + 1))
              continue
            }
            this.setStatusMode('error', this.errorMessageValue)
            return false
          }

          const contentType = response.headers.get('Content-Type') ?? ''
          const html = await response.text()

          if (!contentType.includes('turbo-stream') && !html.includes('<turbo-stream')) {
            console.warn('[infinite-scroll] expected turbo-stream, got', contentType.slice(0, 80))
            if (attempt < MAX_TRANSIENT_RETRIES) {
              await this.delay(RETRY_BASE_MS * (attempt + 1))
              continue
            }
            this.setStatusMode('error', this.errorMessageValue)
            return false
          }

          const beforeCount = this.cards().length
          const streamHadCards = this.turboStreamAppendsCards(html)

          this.mutating = true
          try {
            renderStreamMessage(html)
            this.dedupeCards()
          } finally {
            this.mutating = false
          }

          const afterCount = this.cards().length
          const added = Math.max(0, afterCount - beforeCount)
          this.cachedColumns = null
          this.recomputeWindowSize()
          this.syncMetaFromSentinels()

          if (direction === 'before' && added > 0) {
            this.windowStartValue = offset
            if (anchor != null && document.contains(anchor)) {
              const delta = anchor.getBoundingClientRect().top - anchorTop
              if (delta !== 0) {
                window.scrollBy(0, delta)
              }
            }
            this.maintainWindow('before')
            this.consecutiveDupeSkips = 0
          } else if (direction === 'after' && added > 0) {
            this.maintainWindow('after')
            this.afterFetchCursor = this.windowStartValue + this.cards().length
            this.consecutiveDupeSkips = 0
          }

          this.refreshBounds()

          if (direction === 'after' && added === 0) {
            this.advancePastDeadAfterOffset(offset, limit, streamHadCards)
          }

          this.setupObserver()
          this.clearErrorAndSet('idle')
          this.updateExhaustionUi()

          if (direction === 'after' && this.hasMoreAfter) {
            shouldContinueAfter = true
          } else if (direction === 'after') {
            this.chainAfterDepth = 0
          }

          if (direction === 'before' && this.hasMoreBefore) {
            shouldContinueBefore = true
          } else if (direction === 'before') {
            this.chainBeforeDepth = 0
          }

          return added > 0 || (direction === 'after' ? !this.hasMoreAfter : !this.hasMoreBefore)
        } catch (e) {
          if ((e as Error)?.name === 'AbortError') {
            return false
          }
          console.warn('[infinite-scroll] load error', e)
          if (attempt < MAX_TRANSIENT_RETRIES) {
            await this.delay(RETRY_BASE_MS * (attempt + 1))
            continue
          }
          this.setStatusMode('error', this.errorMessageValue)
          return false
        } finally {
          this.abortController = null
        }
      }

      this.setStatusMode('error', this.errorMessageValue)
      return false
    } finally {
      this.loading = false
      this.setLoadingUi(false, direction)
      if (shouldContinueAfter) {
        this.maybeContinueAfter()
      }
      if (shouldContinueBefore) {
        this.maybeContinueBefore()
      }
    }
  }

  private applyAuthFailure (direction: FetchDirection): void {
    if (direction === 'after') {
      this.hasMoreAfter = false
    } else {
      this.hasMoreBefore = false
    }
    this.setStatusMode('error', this.errorMessageValue)
    this.setupObserver()
  }

  /** True when the turbo-stream payload includes card elements (vs empty page). */
  private turboStreamAppendsCards (html: string): boolean {
    const selector = this.cardSelectorValue !== '' ? this.cardSelectorValue : '.model-card'
    const bare = selector.replace(/^\./, '')
    return html.includes(`class="${bare}`) ||
      html.includes(`class='${bare}`) ||
      html.includes(` ${bare} `) ||
      html.includes(` ${bare}"`) ||
      html.includes(` ${bare}'`)
  }

  /**
   * When a bottom fetch adds no new unique cards, advance the fetch cursor past
   * this offset without moving windowStart (DOM window origin).
   */
  private advancePastDeadAfterOffset (offset: number, limit: number, streamHadCards: boolean): void {
    const step = Math.max(1, limit)
    this.afterFetchCursor = Math.max(this.afterFetchCursor, offset + step)
    this.consecutiveDupeSkips += 1

    if (
      this.consecutiveDupeSkips >= MAX_DUPE_SKIPS ||
      (this.totalCountValue > 0 && this.afterFetchCursor >= this.totalCountValue) ||
      (!streamHadCards && this.totalCountValue <= 0)
    ) {
      this.hasMoreAfter = false
      this.consecutiveDupeSkips = 0
    }
  }

  /**
   * IntersectionObserver often does not re-fire while the sentinel stays
   * intersecting after a sliding-window fetch. Chain another fetch when still
   * at the edge, capped so we do not hammer the server.
   */
  private maybeContinueAfter (): void {
    if (!this.hasMoreAfter || this.loading || this.chainAfterQueued) return
    if (this.chainAfterDepth >= MAX_CHAIN_AFTER) {
      this.chainAfterDepth = 0
      this.scheduleDeferredContinue('after')
      return
    }
    if (!this.nearBottom() && !this.bottomSentinelIntersecting()) return

    this.chainAfterQueued = true
    requestAnimationFrame(() => {
      this.chainAfterQueued = false
      if (!this.hasMoreAfter || this.loading) return
      if (!this.nearBottom() && !this.bottomSentinelIntersecting()) {
        this.chainAfterDepth = 0
        return
      }
      this.chainAfterDepth += 1
      void this.fetchRow('after').then((ok) => {
        if (!ok || !this.hasMoreAfter) {
          this.chainAfterDepth = 0
        }
      })
    })
  }

  private maybeContinueBefore (): void {
    if (!this.hasMoreBefore || this.loading || this.chainBeforeQueued) return
    if (this.chainBeforeDepth >= MAX_CHAIN_BEFORE) {
      this.chainBeforeDepth = 0
      this.scheduleDeferredContinue('before')
      return
    }
    if (!this.nearTop() && !this.topSentinelIntersecting()) return

    this.chainBeforeQueued = true
    requestAnimationFrame(() => {
      this.chainBeforeQueued = false
      if (!this.hasMoreBefore || this.loading) return
      if (!this.nearTop() && !this.topSentinelIntersecting()) {
        this.chainBeforeDepth = 0
        return
      }
      this.chainBeforeDepth += 1
      void this.fetchRow('before').then((ok) => {
        if (!ok || !this.hasMoreBefore) {
          this.chainBeforeDepth = 0
        }
      })
    })
  }

  private scheduleDeferredContinue (direction: FetchDirection): void {
    if (direction === 'after') {
      if (this.deferredAfterTimer != null) return
      this.deferredAfterTimer = window.setTimeout(() => {
        this.deferredAfterTimer = null
        this.maybeContinueAfter()
      }, DEFERRED_CONTINUE_MS)
    } else {
      if (this.deferredBeforeTimer != null) return
      this.deferredBeforeTimer = window.setTimeout(() => {
        this.deferredBeforeTimer = null
        this.maybeContinueBefore()
      }, DEFERRED_CONTINUE_MS)
    }
  }

  private bottomSentinelIntersecting (): boolean {
    return this.sentinelIntersecting(this.bottomSentinelEl())
  }

  private topSentinelIntersecting (): boolean {
    return this.sentinelIntersecting(this.topSentinelEl())
  }

  private sentinelIntersecting (el: HTMLElement | null): boolean {
    if (el == null || typeof el.getBoundingClientRect !== 'function') return false
    const rect = el.getBoundingClientRect()
    const margin = PREFETCH_MARGIN_PX
    return rect.top < window.innerHeight + margin && rect.bottom > -margin
  }

  private dedupeCards (): void {
    const selector = this.cardSelectorValue !== '' ? this.cardSelectorValue : '.model-card'
    const seen = new Set<string>()
    this.gridEl().querySelectorAll<HTMLElement>(`:scope > ${selector}[id]`).forEach((card) => {
      if (seen.has(card.id)) {
        card.remove()
      } else {
        seen.add(card.id)
      }
    })
  }

  private delay (ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms))
  }

  private setLoadingUi (busy: boolean, direction?: FetchDirection): void {
    const grid = this.gridEl()
    if (busy) {
      grid.classList.add('is-loading-more')
      if (direction === 'before') {
        grid.classList.add('is-loading-before')
        grid.classList.remove('is-loading-after')
      } else if (direction === 'after') {
        grid.classList.add('is-loading-after')
        grid.classList.remove('is-loading-before')
      }
      grid.setAttribute('aria-busy', 'true')
      this.setStatusMode('loading', this.loadingMessageValue)
    } else {
      grid.classList.remove('is-loading-more', 'is-loading-before', 'is-loading-after')
      grid.removeAttribute('aria-busy')
      if (this.statusMode === 'loading') {
        this.clearErrorAndSet('idle')
      }
    }
  }

  /**
   * Status modes: error is sticky until clearErrorAndSet (success) or a new
   * in-flight loading announcement. Exhaustion must never clear an error.
   */
  private setStatusMode (mode: StatusMode, text = ''): void {
    if (this.statusMode === 'error' && mode !== 'loading' && mode !== 'error') {
      return
    }
    this.statusMode = mode
    this.writeStatus(mode === 'idle' ? '' : text)
  }

  private clearErrorAndSet (mode: StatusMode, text = ''): void {
    this.statusMode = mode
    this.writeStatus(mode === 'idle' ? '' : text)
  }

  private writeStatus (text: string): void {
    if (!this.hasStatusTarget) return
    this.statusTarget.textContent = text
    if (text.length > 0) {
      this.statusTarget.removeAttribute('hidden')
    } else {
      this.statusTarget.setAttribute('hidden', 'hidden')
    }
  }

  /** End message only when the window covers the true end of the result set. */
  private updateExhaustionUi (): void {
    this.refreshBounds()
    if (!this.hasMoreAfter) {
      this.element.classList.add('is-exhausted')
      if (this.statusMode !== 'error' && this.statusMode !== 'loading') {
        this.clearErrorAndSet('end', this.endMessageValue)
      }
    } else {
      this.element.classList.remove('is-exhausted')
      if (this.statusMode === 'end') {
        this.clearErrorAndSet('idle')
      }
      // Do not clear error or loading from scroll/exhaustion.
    }
  }

  private nearBottom (): boolean {
    const scrollBottom = window.scrollY + window.innerHeight
    const docHeight = document.documentElement.scrollHeight
    return docHeight - scrollBottom < SCROLL_EDGE_PX
  }

  private nearTop (): boolean {
    return window.scrollY < SCROLL_EDGE_PX
  }

  private onScroll (): void {
    if (!this.scrollTicking) {
      this.scrollTicking = true
      requestAnimationFrame(() => {
        this.scrollTicking = false
        this.updateBackToTop()
        if (this.nearBottom() && this.hasMoreAfter) {
          this.chainAfterDepth = 0
          void this.fetchRow('after')
        } else if (this.nearTop() && this.hasMoreBefore) {
          this.chainBeforeDepth = 0
          void this.fetchRow('before')
        }
        this.updateExhaustionUi()
      })
    }
  }

  private updateBackToTop (): void {
    if (!this.hasBackToTopTarget) return
    const show = window.scrollY > BACK_TO_TOP_SHOW_PX
    this.backToTopTarget.toggleAttribute('hidden', !show)
    this.backToTopTarget.classList.toggle('is-visible', show)
  }

  /** Jump to true start of the list (reload page 1 window). */
  private onBackToTop (e: Event): void {
    e.preventDefault()
    const url = new URL(window.location.href)
    url.searchParams.delete('page')
    url.searchParams.delete('offset')
    url.searchParams.delete('per_page')
    url.searchParams.delete('window')
    const path = url.pathname + url.search
    const turbo = (window as unknown as { Turbo?: { visit: (loc: string) => void } }).Turbo
    if (turbo?.visit != null) {
      turbo.visit(path)
    } else {
      window.location.assign(path)
    }
  }

  private stripPageFromUrl (): void {
    const url = new URL(window.location.href)
    let changed = false
    for (const key of ['page', 'offset', 'per_page', 'window']) {
      if (url.searchParams.has(key)) {
        url.searchParams.delete(key)
        changed = true
      }
    }
    if (changed) {
      history.replaceState(history.state, '', url.toString())
    }
  }

  private onBeforeVisit (): void {
    this.persistScrollY()
    this.abortInFlight()
  }

  private storageKey (): string {
    const url = new URL(window.location.href)
    for (const key of ['page', 'offset', 'per_page', 'window']) {
      url.searchParams.delete(key)
    }
    const q = url.searchParams.toString()
    return this.storageKeyPrefixValue + url.pathname + (q.length > 0 ? `?${q}` : '')
  }

  private persistScrollY (): void {
    try {
      sessionStorage.setItem(this.storageKey(), String(Math.round(window.scrollY)))
    } catch {
      // private mode / quota
    }
  }

  private restoreScrollIfNeeded (): void {
    if (this.restoredScroll) return
    this.restoredScroll = true
    let y = 0
    try {
      const raw = sessionStorage.getItem(this.storageKey())
      if (raw == null) return
      y = parseInt(raw, 10)
      sessionStorage.removeItem(this.storageKey())
    } catch {
      return
    }
    if (!Number.isFinite(y) || y < 1) return
    // Double rAF lets image/layout settle after the bootstrap fill.
    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        window.scrollTo(0, y)
        this.updateBackToTop()
      })
    })
  }

  private gridEl (): HTMLElement {
    return this.hasGridTarget ? this.gridTarget : (this.element as HTMLElement)
  }
}
