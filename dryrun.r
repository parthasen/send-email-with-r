library(gmailr)

## edit line below to reflect YOUR json credential filename
gmail_auth("gmailr-tutorial.json", scope = 'compose')

## edit below with email addresses from your life
test_email <- mime(
	To = "PUT_A_VALID_EMAIL_ADDRESS_HERE",
	From = "PUT_YOUR_EMAIL_ADDRESS_HERE",
	Subject = "this is just a gmailr test",
	body = "Can you hear me now?")

ret_val <- send_message(test_email)

## you want to see 200 here
ret_val$status_code

## and you want the email to arrive succesfully!
