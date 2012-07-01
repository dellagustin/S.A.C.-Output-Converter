use IO::File;

sub trim($);
sub parseLine($);
sub buildFormat;
sub buildDate;
sub buildPeriod($);
sub toNumber($);
sub getMonth($);
sub getMonthFromPeriod($);
sub getYearFromPeriod($);

$InFileHandler = IO::File->new($ARGV[0], "r");

if(!defined $InFileHandler)
{ 
	print "Could not open file '$ARGV[0]'.\n";
	exit;
}

# print "Dia;Descrição;Crédito;Débito\n";
print "AccountId;Period;Date;Description;Amount\n";

my $Day;
my $Date;
my $Description;
my $ReadNext = 0;
my $AccountId;
my $CondReaderCte = "Condominio:";
my $Credit;
my $Debit;
my $Amount;
my $FormatedPeriod;

while($InFileRecord = <$InFileHandler>)
{
	# get first character of the line 
	my $FirstChar  = substr($InFileRecord, 0, 1);
	my $CondHeader = substr($InFileRecord, 35, 11);
	my $DayHeader  = substr($InFileRecord, 19, 3);
	my $PeriodHeader = substr($InFileRecord, 110, 11);
	my $SummaryText  = substr($InFileRecord, 35, 25);
	
	if($SummaryText eq "Demonstrativo Consolidado")
	{
		exit;
	}
	
	if($FirstChar  eq " " and
	   $CondHeader ne $CondReaderCte and
	   $DayHeader  ne "Dia")
	{	
		# process regular entry
		my $Result = parseLine($InFileRecord);
	
	    $Credit = toNumber($Result->{ Credit });
		$Debit  = toNumber($Result->{ Debit });
		$Amount	= $Credit - $Debit;
		
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
			# print buildFormat(0, 1, 1, 1);
		}
		else
		{	
			if($Day > 0)
			{
				# check if the entry continues on the next line
				if(length($Credit) == 0 and length($Debit) == 0)
				{
					$ReadNext = "true";		
				}
				else
				{
					$Date = buildDate($Day, $Period);
					print buildFormat(1, 1, 1, 1);	
				}
			}
		}
	}
	elsif($CondHeader eq $CondReaderCte)
	{
		# read the Account Id
		$AccountId = substr($InFileRecord, 48, 4);
	}
	elsif($PeriodHeader eq "Competencia")
	{
		$Period = substr($InFileRecord, 122, 8);
		$FormatedPeriod = buildPeriod($Period);
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
	my $Credit      = substr($InFileRecord, 89, 14);
	my $Debit       = substr($InFileRecord, 74, 14);
	
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

sub buildFormat
{
	my $printDay = $_[0];
	my $printAccount = $_[1];
	my $printAmount = $_[2];
	my $printPeriod = $_[3];
	my $retStr;
	
	if($printAccount == 1)
	{
		$retStr .= "$AccountId;";
	}
	
	if($printPeriod == 1)
	{
		$retStr .= "$FormatedPeriod;";
	}
	
	if($printDay == 1)
	{
		$retStr .= "$Date";
	}
	
	$retStr .= ";";
	
	$retStr .= "$Description;";
	
	if($printAmount == 1)
	{
		$retStr .= "$Amount";
	}
	else
	{
		$retStr .= "$Debit;$Credit";
	}
	
	$retStr .= "\n";
	
	return $retStr;
}

# (12,Out/2011 => 10/12/2011)
sub buildDate
{
	my $Year = substr($_[1], 4, 4);
	my $MonthStr = substr($_[1], 0, 3);
	my $Month;
	
	$Month = getMonth($MonthStr);
	
	return $Month . "/" . $_[0] . "/" . $Year;
}

# Transform Period (Nov/2012 => 2012.11)
sub buildPeriod($)
{
	my $PeriodStr = shift;
	my $FormatedPeriod;
	
	$FormatedPeriod = getYearFromPeriod($PeriodStr) . "." . getMonthFromPeriod($PeriodStr);
	
	return $FormatedPeriod;
}

# transform number strings (6.543,21 => 6543.21)
sub toNumber($)
{
	my $numberAmount = shift;
	$numberAmount =~ s/\.//;
	$numberAmount =~ s/,/./g;
	return $numberAmount;
}

sub getMonth($)
{
	my $MonthStr = shift;
	my $Month;
	
	   if($MonthStr eq "Jan") { $Month = "01"; }
	elsif($MonthStr eq "Fev") { $Month = "02"; }
	elsif($MonthStr eq "Mar") { $Month = "03"; }
	elsif($MonthStr eq "Abr") { $Month = "04"; }
	elsif($MonthStr eq "Mai") { $Month = "05"; }
	elsif($MonthStr eq "Jun") { $Month = "06"; }
	elsif($MonthStr eq "Jul") { $Month = "07"; }
	elsif($MonthStr eq "Ago") { $Month = "08"; }
	elsif($MonthStr eq "Set") { $Month = "09"; }
	elsif($MonthStr eq "Out") { $Month = "10"; }
	elsif($MonthStr eq "Nov") { $Month = "11"; }
	elsif($MonthStr eq "Dez") { $Month = "12"; }
	
	return $Month;
}

# (Nov/2012 => 11)
sub getMonthFromPeriod($)
{
	my $PeriodStr = shift;
	my $Month = getMonth(substr($PeriodStr, 0, 3));
	
	return $Month;
}

# (Nov/2012 => 2012)
sub getYearFromPeriod($)
{
	my $PeriodStr = shift;
	my $Year = substr($PeriodStr, 4, 4);
	
	return $Year;
}