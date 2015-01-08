module DomBuilder

  def table
    content_tag(:table, &Proc.new)
  end

  def tr
    content_tag(:tr, &Proc.new)
  end

  def td
    content_tag(:td, &Proc.new)
  end

  def content_tag(tag_name)
    "<#{tag_name}>" +
      (yield if block_given?).to_s +
      "</#{tag_name}>"
  end

end

