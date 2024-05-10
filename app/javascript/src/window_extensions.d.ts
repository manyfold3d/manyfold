declare module "WindowExtensions" {
  global {
    interface Window {
      tagInputs: Array<JQuery<HTMLElement>>
      i18n
    }
  }
}
