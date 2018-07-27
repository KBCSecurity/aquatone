module Aquatone
  class Summary
    def initialize(domain, visits, ports, options = {})
      @domain  = domain
      @visits  = visits
      @ports = ports
      @options = {
        :per_page => 100,
        :template => "summary"
      }.merge(options)
    end

    def generate(destination)
      sorted_visits = @visits.sort { |x,y| x[:domain] <=> y[:domain] }
      slices        = sorted_visits.each_slice(@options[:per_page].to_i)
      report        = load_template
      slices.each_with_index do |h, i|
        b            = binding
        @visit_slice = h
        @page_number = i

        @link_to_next_page = true
        @next_page_path    = File.basename("report_page_0.html")
	@link_to_previous_page = false

        File.open(summary_file_name(destination), "w") do |f|
          f.write(report.result(b))
        end
      end
    end

    private

    def load_template
      ERB.new(File.read(File.join(Aquatone::AQUATONE_ROOT, "templates", "#{@options[:template]}.html.erb")))
    end

    def h(unsafe)
      CGI.escapeHTML(unsafe.to_s)
    end

    def summary_file_name(destination)
     File.join(destination, "00summary.html")
    end

    def url(domain, port)
      Aquatone::UrlMaker.make(domain, port)
    end

    def header_row_class?(header, value)
      case header.downcase
      when 'server', 'x-powered-by'
        :danger
      when 'access-control-allow-origin'
        :danger if value == '*'
      when 'content-security-policy'
        :success
      when 'x-permitted-cross-domain-policies'
        :success if value.downcase == 'master-only'
      when 'x-content-type-options'
        value = value.join(",")
        if value.downcase == 'nosniff'
          :success
        else
          :danger
        end
      when 'strict-transport-security'
        :success
      when 'x-frame-options'
        :success
      when 'public-key-pins'
        :success
      when 'x-xss-protection'
	value = value.join(",")
        if value.start_with?('1')
          :success
        else
          :danger
        end
      else
        false
      end
    end
  end
end
