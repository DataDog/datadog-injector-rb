# ruby-version-min: 1.8.7

# Reimplement a simple subset of json
#
# In later Ruby versions `json` is a gem, thus `require`-ing it would
# result in a gem activation, which may conflict if a different version is
# bundled by the injectee.

class << self
  # Escape raw string, ready to be enclosed in quotes
  #
  # - backslash    => \\
  # - backspace    => \b
  # - form feed    => \f
  # - newline      => \n
  # - return       => \r
  # - tab          => \t
  # - double quote => \"
  def escape(str)
    buf = str.dup

    # Replace backslash first as others produce backslashes
    buf.gsub!("\\") { |m| '\\\\' }

    buf.gsub!("\b") { |m| '\b' }
    buf.gsub!("\f") { |m| '\f' }
    buf.gsub!("\n") { |m| '\n' }
    buf.gsub!("\r") { |m| '\r' }
    buf.gsub!("\t") { |m| '\t' }
    buf.gsub!('"')  { |m| '\"' }

    buf
  end

  # Serialize basic Ruby types to JSON data types
  #
  # Unknown types are simply stringified
  #
  # Note: this is recursive and does not handle reference loops
  def dump(obj)
    case obj
    when String
      %{"#{escape(obj)}"}
    when Symbol
      %{"#{escape(obj.to_s)}"}
    when Integer, Float
      obj.to_s
    when TrueClass
      'true'
    when FalseClass
      'false'
    when NilClass
      'null'
    when Array
      "[#{obj.map { |e| dump(e) }.join(',')}]"
    when Hash
      "{#{obj.map { |k, v| "#{dump(k)}: #{dump(v)}" }.join(',')}}"
    else
      dump(obj.to_s)
    end
  end
end
