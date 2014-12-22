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