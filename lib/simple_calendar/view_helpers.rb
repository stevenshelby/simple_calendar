module SimpleCalendar
  module ViewHelpers

    def calendar(events, options={}, &block)
      raise 'SimpleCalendar requires a block to be passed in' unless block_given?

      opts = {
          :year       => (params[:year] || Time.zone.now.year).to_i,
          :month      => (params[:month] || Time.zone.now.month).to_i,
          :prev_text  => raw("&laquo;"),
          :next_text  => raw("&raquo;"),
          :start_day  => :sunday,
          :class      => "table table-bordered table-striped calendar",

      }
      options.reverse_merge! opts

      events       ||= []
      selected_month = Date.new(options[:year], options[:month])
      current_date   = Date.today
      range          = build_month_range selected_month, options
      month_array    = build_month range

      draw_calendar(selected_month, month_array, current_date, events, options, block)
    end

    def week_view(events, options={}, &block)
      raise 'SimpleCalendar requires a block to be passed in' unless block_given?

      opts = {
          :year       => (params[:year] || Time.zone.now.year).to_i,
          :week       => (params[:week] || Time.zone.now.to_date.cweek).to_i,
          :prev_text  => raw("&laquo;"),
          :next_text  => raw("&raquo;"),
          :start_day  => :sunday
      }
      options.reverse_merge! opts

      events      ||= []
      selected_week = Date.civil(options[:year]) + (options[:week] - 1).weeks
      date_range    = build_week_range selected_week, options
      month         = build_month date_range

      draw_week_view(date_range, month, events, options, block)
    end

    private

    def week_header(date_range, options)
      content_tag :h2 do
        start_date    = date_range.first
        end_date      = date_range.last
        previous_week = end_date.advance :weeks => -1
        next_week     = end_date.advance :weeks => 1

        tags = []
        tags << week_link(options[:prev_text], previous_week, {:class => "previous-week"})
        tags << "#{I18n.t("date.abbr_month_names")[start_date.month]} #{start_date.day} - #{I18n.t("date.abbr_month_names")[end_date.month]} #{end_date.day} #{end_date.year}"
        tags << week_link(options[:next_text], next_week, {:class => "next-week"})
        tags.join.html_safe
      end
    end

    def build_week_range(selected_week, options)
      start_date = selected_week.beginning_of_week(options[:start_day])
      end_date = selected_week.end_of_week(options[:start_day])
      (start_date..end_date).to_a
    end

    def build_month_range(selected_month, options)
      start_date = selected_month.beginning_of_month
      start_date = start_date.send(options[:start_day].to_s+'?') ? start_date : start_date.beginning_of_week(options[:start_day])

      end_date   = selected_month.end_of_month
      end_date   = end_date.saturday? ? end_date : end_date.end_of_week(options[:start_day])

      (start_date..end_date).to_a
    end

    def build_month(date_range)
      month = []
      week  = []
      i     = 0

      date_range.each do |date|
        week << date
        if i == 6
          i = 0
          month << week
          week = []
        else
          i += 1
        end
      end

      month
    end

    def draw_week_view(date_range, month, events, options, block)
      tags = []
      today = Date.today
      content_tag(:table, :class => "table table-bordered table-striped calendar") do
        tags << week_header(date_range, options)
        tags << content_tag(:thead, content_tag(:tr, date_range.collect { |day| content_tag :th, day, :class => nil}.join.html_safe)) 
        tags << content_tag(:thead, content_tag(:tr, I18n.t("date.abbr_day_names").collect { |name| content_tag :th, name+" ", :class => nil}.join.html_safe))
        tags << content_tag(:tbody, :'data-week'=> date_range.last.month, :'data-year' => date_range.last.year) do

          month.collect do |week|
            content_tag(:tr, :class => (week.include?(Date.today) ? "current-week week" : "week")) do

              week.collect do |date|
                td_class = ["day"]
                #td_class << "today" if today == date
                #td_class << "not-current-month" if selected_month.month != date.month
                #td_class << "past" if today > date
                #td_class << "future" if today < date
                #td_class << "wday-#{date.wday.to_s}" # <- to enable different styles for weekend, etc

                content_tag(:td, :class => td_class.join(" "), :'data-date-iso'=>date.to_s, 'data-date'=>date.to_s.gsub('-', '/')) do
                  content_tag(:div) do
                    divs = []

                    concat content_tag(:div, date.day.to_s, :class=>"day_number")
                    divs << day_events(date, events).collect { |event| block.call(event) }
                    divs.join.html_safe
                  end #content_tag :div
                end #content_tag :td

              end.join.html_safe
            end #content_tag :tr

          end.join.html_safe
        end #content_tag :tbody

        tags.join.html_safe
      end #content_tag :table
    end

    # Renders the calendar table
    def draw_calendar(selected_month, month, current_date, events, options, block)
      tags = []
      today = Date.today
      content_tag(:table, :class => options[:class]) do
        tags << month_header(selected_month, options)
        day_names = I18n.t("date.abbr_day_names")
        day_names = day_names.rotate((Date::DAYS_INTO_WEEK[options[:start_day]] + 1) % 7)
        tags << content_tag(:thead, content_tag(:tr, day_names.collect { |name| content_tag :th, name, :class => (selected_month.month == Date.today.month && Date.today.strftime("%a") == name ? "current-day" : nil)}.join.html_safe))
        tags << content_tag(:tbody, :'data-month'=>selected_month.month, :'data-year'=>selected_month.year) do

          month.collect do |week|
            content_tag(:tr, :class => (week.include?(Date.today) ? "current-week week" : "week")) do

              week.collect do |date|
                td_class = ["day"]
                td_class << "today" if today == date
                td_class << "not-current-month" if selected_month.month != date.month
                td_class << "past" if today > date
                td_class << "future" if today < date
                td_class << "wday-#{date.wday.to_s}" # <- to enable different styles for weekend, etc

                cur_events = day_events(date, events)

                td_class << (cur_events.any? ? "events" : "no-events")

                content_tag(:td, :class => td_class.join(" "), :'data-date-iso'=>date.to_s, 'data-date'=>date.to_s.gsub('-', '/')) do
                  content_tag(:div) do
                    divs = []
                    concat content_tag(:div, date.day.to_s, :class=>"day_number")

                    if cur_events.empty? && options[:empty_date]
                      concat options[:empty_date].call(date)
                    else
                      divs << cur_events.collect{ |event| block.call(event) }
                    end

                    divs.join.html_safe
                  end #content_tag :div
                end #content_tag :td

              end.join.html_safe
            end #content_tag :tr

          end.join.html_safe
        end #content_tag :tbody

        tags.join.html_safe
      end #content_tag :table
    end

    # Returns an array of events for a given day
    def day_events(date, events)
      events.select { |e| e.start_time.to_date == date }
    end

    # Generates the header that includes the month and next and previous months
    def month_header(selected_month, options)
      content_tag :h2 do
        previous_month = selected_month.advance :months => -1
        next_month = selected_month.advance :months => 1
        tags = []

        tags << month_link(options[:prev_text], previous_month, {:class => "previous-month"})
        tags << "#{I18n.t("date.month_names")[selected_month.month]} #{selected_month.year}"
        tags << month_link(options[:next_text], next_month, {:class => "next-month"})

        tags.join.html_safe
      end
    end

    # Generates the link to next and previous months
    def month_link(text, month, opts={})
      link_to(text, "#{simple_calendar_path}?month=#{month.month}&year=#{month.year}", opts)
    end

    # Generates the link to next and previous months
    def week_link(text, day, opts={})
      link_to(text, "#{simple_calendar_path}?week=#{day.cweek}&year=#{day.year}", opts)
    end

    # Returns the full path to the calendar
    # This is used for generating the links to the next and previous months
    def simple_calendar_path
      request.fullpath.split('?').first
    end
  end
end
