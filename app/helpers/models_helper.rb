module ModelsHelper
  def group(files)
    groups = files.group_by { |i| i.filename.split(/[\ _\-:.]/)[0] }
    ungrouped = []
    groups.each_pair do |group, p|
      ungrouped << groups.delete(group)[0] if p.count == 1
    end
    groups.merge(nil => ungrouped)
  end
end
