How to send a bunch of emails from R
=================

We send a fair amount of email in [STAT 545](http://stat545-ubc.github.io). For example, it's how we inform students of their marks on weekly homework and peer review. We use R for essentially all aspects of the course and this is no exception.

In this repo I describe our workflow, with Lord of the Rings characters playing the role of our students.

Key pieces:

  * a project in Google Developers Console to manage your use of the Gmail API
  * the [`gmailr` R package](http://cran.r-project.org/web/packages/gmailr/index.html) by Jim Hester, which wraps the Gmail API (development on [GitHub](https://github.com/jimhester/gmailr))
  * the [`plyr`](http://cran.r-project.org/web/packages/plyr/index.html) and [`dplyr`](http://cran.r-project.org/web/packages/dplyr/index.html) packages for data wrangling (do this with base R if you prefer)
  * `addresses.csv` a file containing email addresses, identified by a __key__. In our case, student names.
  * `marks.csv` a file containing the variable bits of the email you plan to send, including the same identifying __key__ as above.  In our case, the homework marks.
  * the script `send-email-with-r.r` that
    - joins email addresses to marks
    - creates valid email objects from your stuff
    - provides your Gmail credentials
    - sends email
    
FAQ: Can't I "just" do this with sendmail or something from my local machine? In theory, YES. If you can get that working quickly, I salute you -- you clearly don't need this tutorial. For everyone else, I have found this Gmail + `gmailr` approach less exasperating.

*Although this tutorial was written by Jenny Bryan, anything elegant probably comes from TA [Shaun Jackman](http://sjackman.github.io).*

## Prep work related to Gmail and the `gmailr` package

Install the `gmailr` package from CRAN or the development version from GitHub (pick one):

```r
install.packages("gmailr")
## OR ...
devtools::install_github("jimhester/gmailr")
```

Gmail set-up paraphrased from the helpful [`gmailr` vignette](http://cran.r-project.org/web/packages/gmailr/vignettes/sending_messages.html)

- Create a new project at <https://console.developers.google.com/project>
- Navigate to `APIs & auth > APIs`
    - Switch the Gmail API status to `On`
- Navigate to `APIs & auth > Credentials`
    - Create a new client ID. Application type = Installed application. Installed application type = Other.
    - Download JSON for this "Client ID for native application".
    - Look in your downloads folder for a filename along these lines: `client_secret_BLAHBLAHBLAHBLAH.apps.googleusercontent.com.json`
    - *Optional* give this a name that better reflects your bulk emailing project, e.g. `gmailr-tutorial.json`. I made mine match the Google Project name.
    - Move the JSON file to the directory where you bulk emailing project lives.
    - *Optional* if you are using Git, add a line like this to your `.gitignore` file 
    
            gmailr-tutorial.json

Let's do a dry run before we try to send real emails. See `dryrun.r` for code.

Load `gmailr`, call `gmail_auth()` function with the credentials stored in JSON, and declare your intent to compose an email.

```r
library(gmailr)
gmail_auth("gmailr-tutorial.json", scope = 'compose')
```

You will be presented with this question

```
Use a local file to cache OAuth access credentials between R sessions?
1: Yes
2: No

Selection: 
```

No matter what, the first time, you should get kicked into a browser to authorize the application. If you say "No", this will happen every time and is appropriate for interactive execution of your bulk emailing R code. If you say "Yes", a file named `.httr-oauth` will be stored locally so the browser dance won't happen in the future. Choose this if you plan to execute your bulk emailing code at arm's length, e.g. via `Rscript` or Make.

  * *Optional* if you opt for OAuth caching and you're using Git, add this to your `.gitignore` file
  
        .httr-oauth

Use the code in `dryrun.r` to send a test email:

```r
test_email <- mime(
	To = "PUT_A_VALID_EMAIL_ADDRESS_HERE",
	From = "PUT_YOUR_EMAIL_ADDRESS_HERE",
	Subject = "this is just a gmailr test",
	body = "Can you hear me now?")
ret_val <- send_message(test_email)
ret_val$status_code 
```

Is the status code 200? Did your email get through? Do not proceed until the answer is YES.

BTW you can add members to your project from "Permissions" in Google Developers Console, allowing them to also download JSON credentials for the same project.

## Compose and send your emails

The hard parts are over! See `send-email-with-r.r` for clean code to compose and send email. Here's the guided tour.

The file `addresses.csv` holds names and email addresses. The file `marks.csv` holds names and homework marks. (In this case, the LoTR characters receive marks based on the number of words they spoke in the Fellowship of the Ring.) Read those in and join.

```r
library(plyr)
library(dplyr)
library(gmailr)
addresses <- read.csv("addresses.csv", stringsAsFactor = FALSE)
marks <- read.csv("marks.csv", stringsAsFactor = FALSE)
this_hw <- "The Fellowship Of The Ring"
my_dat <- left_join(marks, addresses)
```

Next we create a data.frame where each variable is a key piece of the email, e.g. the "To" field or the body.

```r
email_sender <- 'Peter Jackson <peter@tolkien.com>'
optional_bcc <- 'Anonymous <anon@palantir.org>'      # bcc is probably YOU
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
```

We write this data.frame to `.csv` for an easy-to-read record of the composed emails.

Now authenticate yourself. If you've cached your OAuth credentials this should "just work", though you might see something about refreshing things. If you have not cached, you'll have to do something in your browser.

```r
gmail_auth("gmailr-tutorial.json", scope = 'compose')
```

Now send your emails and save the return value in case you need to do forensics later.

```r
sent <- llply(emails, send_message, .progress = 'text')
saveRDS(sent, paste(this_hw, "sent-emails.rds", sep = "_"))
```

And just to be safe, take a look at the status codes. Hopefully they're uniformly 200, but better safe than sorry.

```r
status.codes <- ldply(sent, .id = 'To', function(x) data.frame(
 	Status.Code = x$status_code,
 	Date = x$headers$date))
uhoh <- status.codes %>% filter(Status.Code != 200)
if (nrow(uhoh) > 0) knitr::kable(uhoh)
```

The end.