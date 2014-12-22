library(plyr)
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(gmailr))

addresses <- read.csv("addresses.csv", stringsAsFactor = FALSE)
marks <- read.csv("marks.csv", stringsAsFactor = FALSE)
this_hw <- "The Fellowship Of The Ring"

my_dat <- left_join(marks, addresses)

email_sender <- 'Peter Jackson <peter@tolkien.com>'
optional_bcc <- 'Anonymous <anon@palantir.org>'      # bcc is optional!

body <- "Hi, %s.

Your mark for %s is %s.

Thanks for participating in this film!
"

emails <- my_dat %>%
	mutate(
		To = sprintf('%s <%s>', name, email),
		Bcc = optional_bcc,
		From = email_sender,
		Subject = sprintf('Mark for %s', this_hw),
		body = sprintf(body, name, this_hw, mark)) %>%
	select(To, Bcc, From, Subject, body)

write.csv(emails, "composed-emails.csv", row.names = FALSE, quote = FALSE)

emails <- dlply(emails, ~ To, function(df) mime(
	To = df$To,
	Bcc = df$Bcc,
	From = df$From,
	Subject = df$Subject,
	body = df$body))
str(emails, list.len = 2)

## what happens here depends on whether you have previously cached OAuth
## credentials; if not, you'll be sent to the browser
gmail_auth("gmailr-tutorial.json", scope = 'compose')

## stuff below is commented out since LoTR character emails are fake!
## de-comment and modify for your purposes
# sent <- llply(emails, send_message, .progress = 'text')
# saveRDS(sent, paste(this_hw, "sent-emails.rds", sep = "_"))
# status.codes <- ldply(sent, .id = 'To', function(x) data.frame(
# 	Status.Code = x$status_code,
# 	Date = x$headers$date))
# uhoh <- status.codes %>% filter(Status.Code != 200)
# if (nrow(uhoh) > 0) knitr::kable(uhoh)
