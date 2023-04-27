# pass get
A pass extension that helps you selectively retrieve usernames, passwords,
PIN's, websites and other data

## Description
`pass get` is an extension for the [pass] utility, providing an easy way to
selectively retrieve data stored in password files.

[pass] proposed a format to store meta data in the password file, where the
password is stored on the first line followed by all other data such as
usernames, passwords, PIN's, websites and other data.

The meta data would follow a format where each piece of data has a field name
separated by a colon `fieldname: data-value`.

A common password file could look like this:
```
Yw|ZSNH!}z"6{ym9pI
URL: *.amazon.com/*
Username: AmazonianChicken@example.com
Secret Question 1: What is your childhood best friend's most bizarre superhero fantasy? Oh god, Amazon, it's too awful to say...
Phone Support PIN #: 84719
```
And to show all the data you would use `pass show <password file>`

However there is no way to selectively retrieve information using the [pass]
utility on its own.

For example: what if you wanted to get the Username of the example above? With
this extension you can use `pass get Username <password-file>` and it would
print `AmazonianChicken@example.com`.

[pass]: https://www.passwordstore.org/
