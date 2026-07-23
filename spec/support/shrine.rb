class ModelFileUploader
  Attacher.promote_block { promote } # promote synchronously
  Attacher.destroy_block { destroy } # destroy synchronously
end
