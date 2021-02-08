module ModelsHelper
  def group(parts)
    groups = parts.group_by { |i| i.filename.split(/[\ _\-:.]/)[0] }
    groups[nil] = []
    groups.each_pair do |group, parts|
      if parts.count == 1
        groups[nil] << groups.delete(group)[0]
      end
    end
  end
end
