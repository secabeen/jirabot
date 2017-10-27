require 'slack-ruby-bot'
require "net/https"
require "uri"

class LSCGBot < SlackRubyBot::Bot
  match(/(\[[0-9]{9}|#\d+)/i) do |client, data, issues|
    puts data.text
    results = []
    message = '```'
    tomatch = data.text
    
    # Remove links from text, since they're already links, by grabbing everything between < and >
    # tomatch = tomatch.sub /(<.+>)/i, ''
    # Removed because links could still be useful now

    # Also remove emoji, because skin-tone-2 and similar were showing up
    tomatch = tomatch.sub /:\b\S*\b:/, ''
    
    # Now grab everything that looks like a LSCG ticket, dump it into an array, grab uniques.
    
    tomatch.scan(/(\[[0-9]{9}|#\d+)/i) do |i,j|
    	results << i.upcase
    end
    results.uniq.each do |ticket|
      if ticket =~ /#/
	ticket = ticket[1..-1]

	uripath = 'https://help.chem.ucsb.edu/rt/REST/1.0/ticket/'+ticket+'/show'
        uri = URI(uripath)

        req = Net::HTTP::Post.new(uri.path)
        req.set_form_data('user' => ENV["RT_USER"], 'pass' => ENV["RT_PASS"])

        res = Net::HTTP.start(uri.hostname, uri.port,
          :use_ssl => uri.scheme == 'https',
          :set_debug_output => $stderr) do |http|
          http.request(req)
        end

        case res
        when Net::HTTPSuccess, Net::HTTPRedirection
          ticketdata = res.body
	  ticketdata.lines.each do |line|
            line.match(/^Subject: (.*)/) do |match|
              message << match[1]+"\n"
            end
            line.match(/^Requestors: (.*)/) do |match|
              message << match[1]+"\n"
            end
	  end
        end
        message << 'https://help.chem.ucsb.edu/rt/Ticket/Display.html?id='+ticket
      else 
	ticket = ticket[1..-1]
        message << 'https://www.lscg.ucsb.edu/helpdesk/tech/editTicket.php?taskid='+ticket
      end
      message << '```'
      client.say(channel: data.channel, text: message)
    end
  end
end

LSCGBot.run
