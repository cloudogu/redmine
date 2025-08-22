# frozen_string_literal: true

# fixes: DEPRECATION WARNING: Defining enums with keyword arguments is deprecated and will be removed
# in Rails 8.0. Positional arguments should be used instead:
# enum :visibility, {:roles=>1, :open=>2}
#  (called from <class:GlobalNoteTemplate> at /usr/share/webapps/redmine/plugins/redmine_issue_templates/app/models/global_note_template.rb:33)

logger = (defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger) || Logger.new($stdout)

roots = [
  Rails.root.join('plugins', 'redmine_issue_templates', 'app', 'models').to_s,
  '/usr/share/webapps/redmine/plugins/redmine_issue_templates/app/models'
].uniq

root = roots.find { |d| Dir.exist?(d) }
if root
  files = Dir.glob(File.join(root, '**', '*.rb'))
  count = 0
  files.each do |path|
    original = File.read(path)
    changed = false

    lines = original.lines.map do |line|
      next line if line.lstrip.start_with?('#')
      if line =~ /^(\s*)enum\s+([a-zA-Z_]\w*):\s*(\{.*\}|\[.*\])(\s*,\s*.*)?$/
        indent, name, values, opts = $1, $2, $3, ($4 || "")
        if values.start_with?('{')
          values = values.gsub(/(\w+):\s*/) { |m| m.include?('=>') ? m : ":#{$1}=>" }
        end
        new_line = "#{indent}enum :#{name}, #{values}#{opts}\n"
        changed ||= (new_line != line)
        new_line
      else
        line
      end
    end

    next unless changed
    File.write(path, lines.join)
    count += 1
  end
  logger.info "[Init:IssueTemplatesEnums] enum patches applied: #{count}"
else
  logger.info "[Init:IssueTemplatesEnums] models dir not found, skip"
end
