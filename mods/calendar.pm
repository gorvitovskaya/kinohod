package mods::calendar;
use lib::table;

sub new {
	my ($class,%args) = @_;
	my $self = bless \%args, $class; 
	($self->{title}, $self->{calendarID}) = $self->{dbh}->select('select name, id from calendars where lnk=?', p=>[$self->{calendar}], line=>1);
	if(CGI::param('popup')){
		$self->makePopup;
		return ($self->{title}, $self->{html}, 1);
	} else {
		$self->makeList;
		return ($self->{title}, $self->{html}, (CGI::param('reloadContent'))?1:0);
	}
}

sub makePopup {
	my $self = shift;
	my $date = CGI::param('date');

	if (CGI::param('save') && CGI::param('new')) {
		$self->{dbh}->insertData('tasks', set=>{
			calID=>$self->{calendarID},
			dt=>$date,
			task=>CGI::param('new'),
		});
	}
	map {
		if (CGI::param('save') && CGI::param('del_'.$_->{id})) {
			$self->{dbh}->delete('tasks', id=>$_->{id});
		}
	}$self->{dbh}->select('select * from tasks where dt=? and calID=?', p=>[$date, $self->{calendarID}]);

	my $table = lib::table->new(align=>'center', 
		border=>0, 
		width=>'100%', 
		cellspacing=>5, 
		cellpadding=>5
	);

	
	my @tasks = $self->{dbh}->select('select * from tasks where dt=? and calID=?', p=>[$date, $self->{calendarID}]);
	$table->addBodyRow(data=>[
		{''},
		{'Удалить', {style=>"font-weight:bold", width=>'10%'}}
	]) if (scalar(@tasks));
	map {
		$table->addBodyRow(data=>[
			{$_->{task}},
			{'<input type="checkbox" name="del_'.$_->{id}.'" value=1>'}
		]);
	}@tasks;
	$table->addBodyRow(data=>[
		{'Новая задача:', {style=>"font-weight:bold"}},
		{''}
	]);
	$table->addBodyRow(data=>[
		{'<input type="text" size="60" name="new">'},
		{''}
	]);

	$self->{html} .= '<form method="post" id="popupForm">';
	$self->{html} .= '<input type="hidden" name="popup" value=1>';
	$self->{html} .= '<input type="hidden" name="date" value='.$date.'>';
	$self->{html} .= $table->getTable;
	$self->{html} .= '</form>';
}

sub makeList {
	my $self = shift;

	my $table = lib::table->new(align=>'center', 
		border=>0, 
		width=>'50%', 
		cellspacing=>5, 
		cellpadding=>5
	);

	my $tasksSTH = $self->{dbh}->prepareSTH("select count(*) from tasks where dt=? and calID=?");
	map {
		my ($day, $monNum, $weekdayNum, $year) = split /\./, $_->{date};
		my $mon = $self->getMonth($monNum);
		my $wd = $self->getWeekDay($weekdayNum);
		my $displayDate = $day.' '.$mon.', '.$wd;
		my $fullDate = $year.'-'.$monNum.'-'.$day;
		my $tasks = $self->{dbh}->runSTH($tasksSTH, p=>[$fullDate, $self->{calendarID}], field=>1);
		my $tasksCount;
		$tasksCount = ($tasks)? $tasks.' '.$self->getTasksWord($tasks) : 'Нет задач';
		$table->addBodyRow(data=>[
			{$displayDate},
			{'<a class="popup" link="/'.$self->{calendar}.'?popup=1&date='.$fullDate.'">'.$tasksCount.'</a>'}
		]);
	}$self->{dbh}->select("SELECT strftime('%d.%m.%w.%Y', 'now', 'weekday 0', '-6 days') date
	union
	SELECT strftime('%d.%m.%w.%Y', 'now', 'weekday 0', '-5 days')
	union
	SELECT strftime('%d.%m.%w.%Y', 'now', 'weekday 0', '-4 days')
	union
	SELECT strftime('%d.%m.%w.%Y', 'now', 'weekday 0', '-3 days')
	union
	SELECT strftime('%d.%m.%w.%Y', 'now', 'weekday 0', '-2 days')
	union
	SELECT strftime('%d.%m.%w.%Y', 'now', 'weekday 0', '-1 days')
	union
	SELECT strftime('%d.%m.%w.%Y', 'now', 'weekday 0')");

	$self->{dbh}->destroySTH($tasksSTH);

	$self->{html} .= '<div id="content">';
	$self->{html} .= '<form id="contentForm" method="post">';
	$self->{html} .= '<input type="hidden" name="reloadContent" value=1>';
	$self->{html} .= $table->getTable;
	$self->{html} .= '</form>';
	$self->{html} .= '</div>';
	$self->{html} .= '<div id="dialog"></div>';
}

sub getTasksWord {
	my ($self, $cnt) = @_;
	my @word = ('задач','задача','задачи','задачи','задачи','задач','задач','задач','задач','задач');
	my $def = $cnt%10;
	return $word[$def];
}

sub getWeekDay {
	my ($self, $weekdayNum) = @_;
	my @wdays = ('Вс','Пн','Вт','Ср','Чт','Пт','Сб');
	return $wdays[$weekdayNum];
}

sub getMonth {
	my ($self, $monNum) = @_;
	my @months = ('января','февраля','марта','апреля','мая','июня','июля','августа','сентября','октября','ноября','декабря');
	return $months[(int($monNum))-1];
}

1;