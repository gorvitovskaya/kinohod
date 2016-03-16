package mods::main;

use lib::table;

sub new {
	my ($class,%args) = @_;
	my $self = bless \%args, $class; 
	my $title = 'Календари';
	if(CGI::param('popup')){
		$self->makePopup;
		return ($title, $self->{html}, 1);
	} else{
		$self->makeList;
		return ($title, $self->{html}, (CGI::param('reloadContent'))?1:undef);
	}
}

sub makeList {
	my $self = shift;

	if (CGI::param('del')) {
		$self->{dbh}->delete('calendars', id=>CGI::param('del'));
		$self->{dbh}->delete('tasks', calID=>CGI::param('del'));
	}

	my $table = lib::table->new(align=>'center', 
		border=>0, 
		width=>'50%', 
		cellspacing=>5, 
		cellpadding=>5
	);
	map {
		$table->addBodyRow(data=>[
			{'<a href="/'.$_->{lnk}.'">'.$_->{name}.'</a>'},
			{$_->{desc}},
			{'<a class="popup" link="/main?popup=1&id='.$_->{id}.'"><img src="/inc/img/edit.png" width=14 height=14></a>'},
			{'<img src="/inc/img/del.png"  width=14 height=14 style="cursor:pointer;" del='.$_->{id}.' deltext="Удалить календарь '.$_->{name}.'?" onclick="deleteImg(this)">'},
		]);
	}$self->{dbh}->select('select * from calendars');

	$table->addBodyRow(data=>[
		{'<button class="popup" link="/main?popup=1">Добавить календарь</button>', {colspan=>2, align=>'center'}}
	]);

	$self->{html} .= '<div id="content">';
	$self->{html} .= '<form id="contentForm" method="post">';
	$self->{html} .= '<input type="hidden" name="reloadContent" value=1>';
	$self->{html} .= $table->getTable;
	$self->{html} .= '</form>';
	$self->{html} .= '</div>';
	$self->{html} .= '<div id="dialog"></div>';
}

sub makePopup {
	my $self = shift;

	my $id = CGI::param('id');
	
	if (CGI::param('save')) {
		if (CGI::param('name')) {
			if ($id) {
				$self->{dbh}->updateData('calendars', set=>{
					name=>CGI::param('name'),
					desc=>CGI::param('desc'),
				}, where=>{id=>$id});
			}
			else {
				$self->{dbh}->insertData('calendars', set=>{
					name=>CGI::param('name'),
					lnk=>$self->getNewLink,
					desc=>CGI::param('desc'),
				});
				$id = $self->{dbh}->select('select last_insert_rowid()', field=>1);
			}
		} else {
			$self->{html} .= '<p style="color:red">Название календаря не может быть пустым.</p>';
		}
	}

	my ($calendarInfo) = $self->{dbh}->select('select * from calendars where id=?',p=>[$id]) if ($id);

	my $table = lib::table->new(align=>'center', 
		border=>0, 
		width=>'100%', 
		cellspacing=>5, 
		cellpadding=>5
	);
	$table->addBody(
		{data=>[
			{'Название'},{'<input type="text" size="40" name="name" value="'.$calendarInfo->{name}.'">'},
		]},{data=>[
			{'Описание'},{'<input type="text" size="40" name="desc" value="'.$calendarInfo->{desc}.'">'}
		]},
	);

	$self->{html} .= '<form method="post" id="popupForm">';
	$self->{html} .= '<input type="hidden" name="popup" value=1>';
	$self->{html} .= '<input type="hidden" name="id" value='.$id.'>';
	$self->{html} .= $table->getTable;
	$self->{html} .= '</form>';
}

sub getNewLink {
	my $self = shift;
	my @syms = split(//, 'abcdefg1234');
	my $newLink; my $newLinkFlag;
	while ($newLinkFlag !=1) {
		my $gen; map {$gen .= $syms[rand @syms];}(0..15);
		my $exist = $self->{dbh}->select('select count(*) from calendars where lnk=?', p=>[$gen], field=>1);
		$newLinkFlag = 1 if(!$exist);
		$newLink = $gen;
	}
	return $newLink;
}

1;