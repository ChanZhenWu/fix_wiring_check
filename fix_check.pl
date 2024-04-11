print "\n*****************************************************************************\n";
print "  3070 wiring check script <v0.1>\n";
print "  Author: Noon Chen\n";
print "  A Professional Tool for Test.\n";
print "  ",scalar localtime;
print "\n*****************************************************************************\n";

use strict;
use warnings;

############################### process fixture.o ########################################

print  "\n  >>> processing fixture.o ... \n";
my $Nnum = 0;	#node numbers
my $Wnum = 0;   #Wire numbers
my @shorts = ();
my @pins =();

open (fix_pins, ">fix_pins");
open (fix_shorts, ">fix_shorts");

open (Fixture, "< ./fixture/fixture.o");
open (Report, ">Details.txt");
	while(my $LIST = <Fixture>)
		{
		$LIST =~ s/(^\s+|\s+$)//g;		#clear all non-character symbol
		next if(!$LIST);				#goto next if it's empty
		my @node = split('\s+', $LIST);
		if ($LIST eq "PROTECTED UNIT"){last;}

		if($node[0] eq "NODE")
			{
			$Nnum++;
			print "$node[1]  \#$Nnum\n";
			print Report "  #$Nnum\n";
			print Report "$node[1]\n";
			while($LIST = <Fixture>)
				{
				$LIST =~ s/(^\s+|\s+$)//g;
				last if(!$LIST);		#exit loop if it's none-character symbol				
				if($LIST eq "PINS")
					{
					my @pair = ();
					#print @pair."\n";
					my $BRCnum = 1;	#BRC numbers
					while($LIST = <Fixture>)
						{
						$LIST =~ s/(^\s+|\s+$)//g;	   #clear all non-character symbol
						goto NEXT_NODE if(!$LIST|$LIST eq "PROBES");		#exit loop if it's none-character symbol
						my ($BRC) = $LIST =~ /(\d+)/;
						next if(substr($BRC,-2) =~ /(19|20|39|40|59|60)/);	#eliminate fixed GROUND
						next if(substr($BRC,0,3) =~ /(201|213|111|123|106|118|206|218)/);	#eliminate ASRU/Control card				
						$Wnum++;
						print $BRC."  \#$Wnum\n";
						print Report $BRC."\n";
						push(@pair, $BRC);
						#if($BRCnum > 1){ print scalar(@pair)."\n"; print $pair[$BRCnum-1]."\n"; print "@pair\n\n";}		#write shorts file
						if($BRCnum > 1)		#collect shorts data
							{
							my $short_pair = $pair[$BRCnum-2]." to ".$pair[$BRCnum-1]."  \!".$node[1]."\n";
							print $short_pair;
							push(@shorts, "short ".$short_pair);
							push(@pins, "nodes ".$BRC."  \!$node[1]\n");
							#print @shorts;
						}
						else		#collect pins data
							{
							push(@pins, "nodes ".$BRC."  \!$node[1]\n");
						}
						$BRCnum++;
					}
				}
			}
		}
	NEXT_NODE:
	}
	print fix_shorts "  threshold 12\n  settling delay 1m\n";
	print fix_shorts sort @shorts;
	print fix_shorts "  threshold 1000\n";
	print fix_shorts sort @pins;
	print fix_pins sort @pins;

close Report;
close Fixture;
close fix_shorts;
close fix_pins;


print "\n  >>> done ...\n\n";


##########################################################################################


