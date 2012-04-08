use IO::File;

sub trim($);
sub parseLine($);

$InFileHandler = IO::File->new($ARGV[0], "r");

if(!defined $InFileHandler)
{ 
	print "Could not open file '$ARGV[0]'.\n";
	exit;
}

print "Dia;Descrição;Crédito;Débito\n";

my $Day;
my $Description;
my $ReadNext = 0;

while($InFileRecord = <$InFileHandler>)
{
	# get first character of the line 
	my $FirstChar  = substr($InFileRecord, 0, 1);
	my $CondHeader = substr($InFileRecord, 35, 11);
	my $DayHeader  = substr($InFileRecord, 19, 3);
	
	if($FirstChar  eq " " and
	   $CondHeader ne "Condominio:" and
	   $DayHeader  ne "Dia")
	{	
		# process regular entry
		my $Result = parseLine($InFileRecord);
	
	    my $Credit      = $Result->{ Credit };
		my $Debit       = $Result->{ Debit };
		
		if($ReadNext)
		{
			$Description = $Description . " " . $Result->{ Description };
			$ReadNext = 0;
		}
		else
		{
			$Day         = $Result->{ Day };
			$Description = $Result->{ Description };
		}
		
		if($Description eq "Saldo Anterior")
		{
			print ";$Description;$Debit;$Credit\n";
		}
		else
		{	
			if($Day > 0)
			{
				if(length($Credit) == 0 and length($Debit) == 0)
				{
					$ReadNext = "true";		
				}
				else
				{
					print "$Day;$Description;$Debit;$Credit\n";	
				}
			}
		}
	}
	elsif($FirstChar eq "*")
	{
		# print account page break
		print "$InFileRecord";
	}
}

sub trim($)
{
	my $string = shift;
	
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

sub parseLine($)
{
	my $fileLine = shift;

	my $Day         = int(substr($InFileRecord, 20, 2));
	my $Description = substr($InFileRecord, 26, 48);
	my $Credit      = substr($InFileRecord, 74, 14);
	my $Debit       = substr($InFileRecord, 89, 14);
	
	$Description    = trim($Description);
	$Credit         = trim($Credit);
	$Debit          = trim($Debit);
	
	my $Result = 
	{
		Day         => $Day,
		Description => $Description,
		Credit      => $Credit,
		Debit       => $Debit,	
	};
}