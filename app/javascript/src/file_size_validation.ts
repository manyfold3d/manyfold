const validateFileSizes = (fileList: FileList, maxSize: number): boolean => {
  for (const file of fileList) {
    if (file.size > maxSize) {
      return false
    }
  }
  return true
}

document.addEventListener('ManyfoldReady', () => {
  document.querySelectorAll('input[data-max-size]').forEach((input: HTMLInputElement) => {
    input.addEventListener('change', () => {
      if ((input.files != null) && (input.dataset.maxSize != null) && !validateFileSizes(input.files, parseInt(input.dataset.maxSize))) {
        input.setCustomValidity(window.i18n.t('models.exceeds_max_size', { max_size: (parseInt(input.dataset.maxSize) / 1024 / 1024).toPrecision(3) }))
      }
    })
  })
})
