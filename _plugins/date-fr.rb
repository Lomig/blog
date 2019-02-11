# coding: utf-8
module Jekyll
  module DateFR
    MONTHS = {"01" => "janvier",
              "02" => "février",
              "03" => "mars",
              "04" => "avril",
              "05" => "mai",
              "06" => "juin",
              "07" => "juillet",
              "08" => "août",
              "09" => "septembre",
              "10" => "octobre",
              "11" => "novembre",
              "12" => "décembre"
             }

    def date_to_french(date)
      day = time(date).strftime("%-d")
      month = time(date).strftime("%m")
      year = time(date).strftime("%Y")

      day = day == "1" ? "1er" : day

      "Le #{day} #{MONTHS[month]} #{year}"
    end
  end
end

Liquid::Template.register_filter(Jekyll::DateFR)
