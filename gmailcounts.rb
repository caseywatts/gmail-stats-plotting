##!/usr/bin/env ruby

require 'pathname'
require 'rubygems'

# overkill for including easy time expressions from rails
require 'activesupport'

# only needed if accepting command line input - but keychain is better long term?
require "highline/import" 

# sudo gem install gmail
# Note: this is an improved version of Daniel Parker's ruby-gmail
# http://rubydoc.info/gems/gmail/0.3.4/frames
require 'gmail'

# sudo gem install fastercsv
require 'csv'



begin
  USERNAME = ask("Enter email address:")
  PASSWORD = ask("Enter password for " + USERNAME) { |q| q.echo = "x" }


  gmail = Gmail.connect(USERNAME, PASSWORD)

  #Number read so far today
  todaysofar = gmail.mailbox("[Gmail]/All Mail").count(:read, :on => Date.today)
  puts "Number read emails today (so far) = " + todaysofar.to_s

  #Number unread so far today
  todaysofar = gmail.mailbox("[Gmail]/All Mail").count(:unread, :on => Date.today)
  puts "Number unread emails today (so far) = " + todaysofar.to_s



  #Count the number of incoming and outgoing messages per week, past n weeks
  puts "In/Out by week. How many weeks?"
  numweeks = gets.chomp.to_i

  #Start counting from the last full week
  refdate = Date.today.end_of_week - 1.day - 1.week
  if numweeks > 0
    puts "\nWeek End Date\tIn Count\tOut Count"
    numweeks.times do
      incount = gmail.mailbox('[Gmail]/All Mail').count(:read, :after => (refdate), :before => (refdate+1.week)).to_s
      outcount = gmail.mailbox('[Gmail]/Sent Mail').count(:after => (refdate), :before => (refdate+1.week)).to_s
      puts refdate.to_s + "\t" + incount + "\t" + outcount + "\n"
      refdate = refdate - 1.week
    end
  end



  #Count the number of incoming and outgoing messages per day, past n days
  puts "In/Out by day. How many days?"
  numdays = gets.chomp.to_i

  CSV_FILE = "gmail-counts.csv"
  CSV.open(CSV_FILE, "w") do |csv|
    csv << ["date", "incoming", "outgoing"]

    #Start counting from the last full day
    refdate = Date.today - 1.day
    if numdays > 0
      puts "\nDate\tIn Count\tOut Count"
      numdays.times do
        incount = gmail.mailbox('[Gmail]/All Mail').count(:read, :after => (refdate), :before => (refdate+1.day)).to_s
        outcount = gmail.mailbox('[Gmail]/Sent Mail').count(:after => (refdate), :before => (refdate+1.day)).to_s
        puts refdate.to_s + "\t" + incount + "\t" + outcount + "\n"
        csv << [refdate.to_s, incount, outcount]
        refdate = refdate - 1.day
      end
    end
  end
  

  #Count number of incoming and outgoing messages over the past week
  #refdate = Date.today
  #7.times do
  #incount = gmail.mailbox('[Gmail]/All Mail').count(:read, :after => (refdate-1.day), :before => refdate).to_s
  #outcount = gmail.mailbox('[Gmail]/Sent Mail').count(:after => (refdate-1.day), :before => refdate).to_s
  #puts refdate.to_s + "\t" + incount + "\t" + outcount + "\n"
  #refdate = refdate - 1.day
  #end


  #Try to determine response rate
  #Skipped every time for now.
  if false
    gmail.mailbox('[Gmail]/Sent Mail').find(:after => (refdate-1.week), :before => refdate).each do |mail|
      #puts mail.subject + mail.date
      #mails(:query => ['HEADER', 'Message-ID', email.message_id])
      originalmail=nil
      if mail.references
        replydate = Time.parse(mail.date)
        #gmail.mailbox("[Gmail]/Sent Mail").emails.last.header("In-Reply-To")
        originalmailid = mail.references.last
        originalmail = gmail.mailbox('[Gmail]/All Mail').mails(:query => ['HEADER', 'Message-ID', originalmailid])
        unless originalmail.empty?
          incomingdate = Time.parse(originalmail[0].date)
          timeinterval = replydate - incomingdate
          timeinterval = timeinterval/60/60 #converting to hours
          puts timeinterval.to_s + " = " + mail.subject.to_s
        end
      end
    end
  end


  #Plot emails by day of week
  puts "In/Out by day of week. How many weeks?"
  numweeks = gets.chomp.to_i

  if numweeks > 0
    outputdata = {}
    date = Date.today - 1.day
    puts "\nWeek Day\tIn Count\tOut Count"

    #iterate over the past numweeks
    (7*numweeks).times do
      dayofweek = date.strftime("%w")
      outputdata[dayofweek] ||= {}
      outputdata[dayofweek]["in"] ||= 0
      outputdata[dayofweek]["out"] ||= 0
      incount = gmail.mailbox('[Gmail]/All Mail').count(:read, :after => (date), :before => (date+1.day)).to_s
      outcount = gmail.mailbox('[Gmail]/Sent Mail').count(:read, :after => (date), :before => (date+1.day)).to_s
      outputdata[dayofweek]["in"] = outputdata[dayofweek]["in"] + incount.to_i
      outputdata[dayofweek]["out"] = outputdata[dayofweek]["out"] + outcount.to_i
      date -= 1.day
    end
    keys = outputdata.keys.sort
    keys.each do |key|
      puts key + "\t" + outputdata[key]["in"].to_s + "\t" + outputdata[key]["out"].to_s + "\n"
    end
  end



  #####  This gmail gem rounds to the nearest day for its queries  ####
  ##Determine what time of day emails are recieved
  #outputdata = {}

  ##yesterday is the most recent full day, start there
  #date = Date.today - 1.day
  #outputdata[date.to_s] = {}

  ##iterate over the past 31 days
  #1.times do
  #time = date.beginning_of_day
  #4.times do
  ##now we have a date and a time (both in "time")
  #incount = gmail.mailbox('[Gmail]/All Mail').count(:read, :after => (time-1.hour), :before => (time)).to_s
  #outputdata[date.to_s][time.strftime("%H")] = incount
  #time += 1.hour
  #end

  #date += 1.day
  #end


rescue ArgumentError => e
  puts e
end



gmail.logout
