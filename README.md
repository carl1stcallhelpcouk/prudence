# prudence

## System update automation scripts.

### Usage :- 

	update_new.sh [options]

### Options :- 

	-m, --mailto <email>            Address to send notification email to.  See also -s, --sendmail.
    								default = 'carlmcalwane@hotmail.co.uk'.
	-l, --logfile <logfile name>	Logfile name.  Default =  /var/log/update_new.sh.log.  
									'\*\*NOLOG\*\*' = no logging.
	-q, --quiet                     Don't display any output to STDOUT.
	-v, --verbose                   Use verbose logging and output.
	-s, --sendmail <true | false>   Send notification email to <mailto> address.  See also -m, --mailto.
									Default = 'true'.  'true' if parameter is ommited.
	-u, --doupdate <true | false>   Do 'apt-get update'.  
									Default = 'true'.  'true' if parameter is ommited.
	-g, --doupgrade <true | false>  Do 'apt-get upgrade'.
									Default = 'true'.  'true' if parameter is ommited.
	-c, --doclean <true | false>    Do 'apt-get autoremove'.
									Default = 'true'.  'true' if parameter is ommited.
	-b, --background <true | false> Execute in background.
									Default = 'false'.  'true' if parameter is ommited.
	-h, --help                      Show this help text.
	-o, --showoptions               Show configured options.
