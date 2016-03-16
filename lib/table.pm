package lib::table;

sub new {
	my $class = shift;
	my $self = bless {}, $class;
	my %cfg = @_;
	map { $self->{tableAttrs} .= " ".$_." = '".$cfg{$_}."'" ;}keys %cfg;
	$self->{xls} = 1 if ($cfg{xls});
	return $self;
}

sub addHead {
	my ($self, %cfg) = @_;

	my $trAttr = $self->getAttr(%{$cfg{attr}}) if ($cfg{attr});
	my $row = qq(<tr$trAttr>);
	map {$row .= qq(<th>&nbsp;</th>)} (0..$cfg{firstEmpty}-1);

	map {
		if (ref(\$_) eq 'SCALAR') {
			$row .= qq(<th>$_</th>);
		} else {
			if ($cfg{valueField}) {
				$row .= qq(<th>$_->{$cfg{valueField}}</th>) 
				} else {
					my %line = %{$_};
					map {
						my $tdAttr = $self->getAttr(%{$line{$_}});
						$row .= qq(<th$tdAttr>$_</th>);
					} keys %line;
					undef %line;
				}
		}
	}@{$cfg{data}};

	map {$row .= qq(<th>&nbsp;</th>)} (0..$cfg{lastEmpty}-1);

	$row .= qq(</tr>);
	$self->{thead} = $row;
	undef %cfg; undef $trAttr; undef $row; 
}

sub addBody {
	my ($self, @data) = @_;
	map {
		$self->addBodyRow(%{$_});
	} @data;
	undef @data;
}

sub addBodyRow {
	my ($self, %cfg) = @_;
	my $trAttr = $self->getAttr(%{$cfg{attr}}) if ($cfg{attr});
	my $row = qq(<tr$trAttr>);

	map {
		my %line = %{$_};
		map {
			my %attrHash = 	%{$line{$_}};
			my $tdAttr = $self->getAttr(%attrHash);
			$row .= qq(<td$tdAttr>);
			$row .= $_;
			$row .= qq(</td>);
			undef %attrHash; undef $tdAttr;
		} keys %line;
		undef %line;
	}@{$cfg{data}};
	$row .= qq(</tr>);
	$self->{tbody} .= $row;
	undef %cfg; undef $trAttr; undef $row; 
}

sub getTable {
	my $self = shift;
	my $html = '';
	if ($self->{xls}) {
		my $id;
		for (0..10) { $id .= chr( int(rand(25) + 65) ); }
		$html .= qq(<div class="right"><a href="javascript:sendToExcel('$id');"><img src="/base/templates/img/xls.png" alt="Export to Excel" width="20"></a></div>);
		$html .= qq(<div id ="$id">);
	}
	$html .= qq(<table $self->{tableAttrs}>);
	$html .= qq(<thead>$self->{thead}</thead>) if (defined $self->{thead});
	$html .= qq(<tbody>$self->{tbody}</tbody>);
	$html .= qq(</table>);
	$html .= qq(</div>) if ($self->{xls});
	$self->DESTROY;
	return $html;
}

sub getAttr {
	my ($self, %hash) = @_;
	my $trAttr;
	map { $trAttr .= " $_='$hash{$_}'" if ($_ ne 'edt' && $_ ne 'form' && $hash{$_})} keys %hash;
	undef %hash;
	return $trAttr;

}

sub DESTROY {
	my $self = shift;
	undef $self;
}

1;