require 'slack-ruby-bot'
require "net/https"
require "uri"
require 'pp'
require 'mysql'

class LSCGBot < SlackRubyBot::Bot
  match(/(\[[0-9]{9}|#\d+|@[A-Z][A-Za-z]+)/) do |client, data, issues|
    puts data.text
    results = []
    tomatch = data.text
    
    # Remove links from text, since they're already links, by grabbing everything between < and >
    # tomatch = tomatch.sub /(<.+>)/i, ''
    # Removed because links could still be useful now

    # Also remove emoji, because skin-tone-2 and similar were showing up
    tomatch = tomatch.sub /:\b\S*\b:/, ''
    
    # Now grab everything that looks like a LSCG ticket, dump it into an array, grab uniques.
    
    tomatch.scan(/(\[[0-9]{9}|#\d+|@[A-Z][A-Za-z]+)/) do |i,j|
      results << i
    end
# Does not work yet
=begin
    tomatch.scan(/Display.html\?id=(\d+)/) do |i,j|
      results << i.upcase
    end
=end
    results.uniq.each do |ticket|
      message = ''
      ticketinfoarray = []
      ticketinfo = {}
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
              ticketinfo["text"] = match[1]+"\n"
            end
            line.match(/^Requestors: (.*)/) do |match|
              ticketinfo["author_name"] = match[1]+"\n"
            end
	  end
	  ticketinfoarray.push(ticketinfo)
        end
        message << 'https://help.chem.ucsb.edu/rt/Ticket/Display.html?id='+ticket+"\n"
      end
      if ticket =~ /\[\d+/
	ticket = ticket[1..-1]

	con = Mysql.new(ENV["MY_HOSTNAME"], ENV["MY_USER"], ENV["MY_PASS"], ENV["MY_DB"])
	rs = con.query('select * from tickets where id = '+ticket+' limit 1')
        record = rs.fetch_hash

	unless record.nil?
	  ticketinfo["text"] = record["task_title"]
	  ticketinfo["author_name"] = record["user"]+' '+record["email"]
	  ticketinfoarray.push(ticketinfo)
	end

	con.close

        message << 'https://www.lscg.ucsb.edu/helpdesk/tech/editTicket.php?taskid='+ticket+"\n"
      end
      if ticket =~ /@[A-Z][A-Za-z]+/
	mentionuser = ticket.downcase
        message << mentionuser+"\n"
      end
      client.web_client.chat_postMessage(channel: data.channel, text: message, attachments: ticketinfoarray.to_json, as_user: true)
    end
  end
end

LSCGBot.run
