package lib::DB;
use DBI;

sub new {
	my ($class,%args) = @_;
	my $self = bless \%args, $class; 
	$self->connectDB if (!$self->{dbh});
   	return $self;
}

sub connectDB {
	my $self = shift;

	my $database = "db/test.db";
	my $dsn = "DBI:SQLite:dbname=$database";
	my $userid = "";
	my $password = "";
	$self->{dbh} = DBI->connect($dsn, $userid, $password, { 
		RaiseError => 1, 
		ShowErrorStatement => 1,
		AutoCommit		=> 1,
	}) or die $DBI::errstr;

	$self->dbStructure;
}

sub dbStructure {
	my $self = shift;
	my $stmt;

	my $calendarsTableExist = $self->select("SELECT count(*) FROM sqlite_master WHERE type='table' AND name=?", p=>['calendars'], field=>1);
	if (!$calendarsTableExist) {
		$stmt = qq(CREATE TABLE calendars
		      (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL ,
		       name           CHAR(255) NOT NULL,
		       desc           CHAR(255) ,
		       lnk            CHAR(255) NOT NULL
		       ););
		$self->{dbh}->do($stmt);
		$self->insertData('calendars', set=>{name=>'Main Calendar', lnk=>'maincalendar', desc=>'Основной календарь для тестового задания'});
	}
	my $tasksTableExist = $self->select("SELECT count(*) FROM sqlite_master WHERE type='table' AND name=?", p=>['tasks'], field=>1);
	if (!$tasksTableExist) {
		$stmt = qq(CREATE TABLE tasks
		      (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL ,
		       calID		  INTEGER   NOT NULL,	
		       dt		  	  DATE      NOT NULL,	
		       task           CHAR(255) NOT NULL
		       ););
		$self->{dbh}->do($stmt);
		$self->insertData('tasks', set=>{calID=>1, task=>'Задача 1', dt=>'2016-03-16'});
		$self->insertData('tasks', set=>{calID=>1, task=>'Задача 2', dt=>'2016-03-16'});
		$self->insertData('tasks', set=>{calID=>1, task=>'Задача 3', dt=>'2016-03-16'});
		$self->insertData('tasks', set=>{calID=>1, task=>'Задача 1', dt=>'2016-03-18'});
		$self->insertData('tasks', set=>{calID=>1, task=>'Задача 2', dt=>'2016-03-18'});
		$self->insertData('tasks', set=>{calID=>1, task=>'Задача 1', dt=>'2016-03-20'});
		$self->insertData('tasks', set=>{calID=>1, task=>'Задача 2', dt=>'2016-03-20'});
		$self->insertData('tasks', set=>{calID=>1, task=>'Задача 3', dt=>'2016-03-20'});
		$self->insertData('tasks', set=>{calID=>1, task=>'Задача 4', dt=>'2016-03-20'});
		$self->insertData('tasks', set=>{calID=>1, task=>'Задача 5', dt=>'2016-03-20'});
	}
	

}

sub delete {
	my ($self, $table, %cfg) = @_;
	my $sql = 'delete from '.$table.' where ';
	$sql .= join ' and ', grep {$_} map { $_." = ".$self->addQuotes($cfg{$_}) if $_ ne 'dbg'; } keys %cfg;
	$self->{dbh}->do($sql);
}

sub insertData {
	my ($self, $table, %cfg) = @_;

	my $sql = '';
	$sql .= 'insert into '.$table;

	my @cols; my @vals;

	my %set = %{$cfg{set}};
	map {
		$set{$_} =~ s/&/&amp;/g;
		$set{$_} =~ s/^\s+//g; 
		$set{$_} =~ s/\s+$//g;  
		$set{$_} =~ s/'/&#39;/g;  
		$set{$_} =~ s/</&lt;/g;  
		$set{$_} =~ s/>/&gt;/g;  
		$set{$_} =~ s/\\/&#92;/g;
		push @cols, $_;
		push @vals, $self->addQuotes($set{$_});
	} keys %set;

	$sql .= ' ('. (join ', ', @cols) .')';
	$sql .= ' values ('. (join ', ', @vals) .')';

	$self->{dbh}->do($sql);

	undef @vals; undef @cols;
	%set = {};
	%cfg = {};
	undef $sql;
}

sub updateData {
	my ($self, $table, %cfg) = @_;

	my $sql = '';
	$sql .= 'update '.$table." set ";

	my %set = %{$cfg{set}};
	$sql .= join ', ', map {
		$set{$_} =~ s/&/&amp;/g;
		$set{$_} =~ s/^\s+//g; 
		$set{$_} =~ s/\s+$//g;  
		$set{$_} =~ s/'/&#39;/g;  
		$set{$_} =~ s/</&lt;/g;  
		$set{$_} =~ s/>/&gt;/g;  
		$set{$_} =~ s/\\/&#92;/g;
		$_." = ".$self->addQuotes($set{$_}); 
	} keys %set;

	if ($cfg{where}) {
		$sql .= ' where ';
		my %where = %{$cfg{where}};
		$sql .= join ' and ', map { $_. " = ".$self->addQuotes($where{$_}); } keys %where;
	}
	$self->{dbh}->do($sql);
	%set = {};
	%cfg = {};
	undef $sql;
}

sub addQuotes {
	my ($self, $val) = @_;
	if ($val !~ /^!/) {$val= "'".$val."'";}
	else {$val =~ s/!//}
	return $val; 
}

sub select {
	my ($self, $sql, %cfg) = @_;
	my $sth = $self->{dbh}->prepare($sql);
	$self->runSTH($sth, %cfg);
}

sub prepareSTH {
	my ($self, $sql) = @_;
	return $self->{dbh}->prepare($sql);
}

sub runSTH {
	my ($self, $sth, %cfg) = @_;
	my @sqlParams = @{$cfg{p}||[]};
	
	$sth->execute(@sqlParams); 

	my $retVar;
	my @retArray;
	my %retHash;

	if ( $cfg{line} ) {
		@retArray = $sth->fetchrow;
	} elsif ( $cfg{field} ) {
		$retVar = $sth->fetchrow;
	} elsif ( $cfg{hash} ) {
		 %retHash = %{$sth->fetchall_hashref($cfg{hash})};
	} else {
		@retArray = @{$sth->fetchall_arrayref({})};
	}
	$self->destroySTH($sth);

	return $retVar if ($cfg{field});
	return %retHash if ($cfg{hash});
	return @retArray;
}

sub destroySTH {
	my ($self, $sth) = @_;
	$sth->finish;
	$sth->DESTROY;
}


sub DESTROY {
	my $self = shift;
	map {
		$self->{$_}->disconnect if (ref($self->{$_}) =~ /DB/);
		} keys %{$self};
}

1;