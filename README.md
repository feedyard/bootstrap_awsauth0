# bootstrap_aws_auth0

description


Implementation steps

1. manual add auth0 to github organization, get id and secrets and add to auth0 account social connection

code assumes the existance of two yaml files.

secrets.yml

auth0:<br/>
&nbsp;&nbsp;domain: 'example.auth0.com'<br/>
&nbsp;&nbsp;client_id: 'asdfgh'<br/>
&nbsp;&nbsp;client_secret: '12345asdf'<br/>
aws_accounts:<br/>
&nbsp;&nbsp;account-one:<br/>
&nbsp;&nbsp;&nbsp;&nbsp;account_id: 123...<br/>
&nbsp;&nbsp;&nbsp;&nbsp;aws_access_key_id: "AKIA..."<br/>
&nbsp;&nbsp;&nbsp;&nbsp;aws_secret_access_key:  "IHQ3h..."<br/>
&nbsp;&nbsp;account-two:<br/>
&nbsp;&nbsp;&nbsp;&nbsp;account_id: 321...<br/>
&nbsp;&nbsp;&nbsp;&nbsp;aws_access_key_id: "HJIA..."<br/>
&nbsp;&nbsp;&nbsp;&nbsp;aws_secret_access_key:  "ISD3h..."<br/>
&nbsp;&nbsp;...<br/>