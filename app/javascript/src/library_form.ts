import { Collapse } from 'bootstrap'

document.addEventListener('ManyfoldReady', () => {
  const updateSections = (active: string) => {
    const selected = 'options-' + active
    document.querySelectorAll('.storage-collapse').forEach((section: HTMLDivElement) => {
      const control = Collapse.getOrCreateInstance(section, { toggle: false })
      if (section.id === selected) {
        control.show()
      } else {
        control.hide()
      }
    })
  }

  document.querySelectorAll('#library_storage_service').forEach((select: HTMLSelectElement) => {
    updateSections(select.value)
    select.addEventListener('change', (event: Event) => {
      if (event.target != null) {
        updateSections((event.target as HTMLSelectElement).value)
      }
    })
  })
})
