package Data::MuForm::Renderer::Base;
# ABSTRACT: Renderer

use Moo;

=head1 NAME

Data::MuForm::Renderer::Base

=head1 DESCRIPTION

Base functionality for renderers, including rendering standard form elements.

=cut

has 'localizer' => ( is => 'rw' );

has 'html_filter' => ( is => 'rw', default => sub { *default_html_filter } );

has 'layouts' => ( is => 'rw', builder => 'build_layouts' );

sub build_layouts {
    my $self = shift;
    my $layouts = {
        bare => *layout_bare,
        simple => *layout_simple,
        w_errs => *layout_w_errs,
    };
    return $layouts;
}

sub layout_bare {
    my ( $self, $rargs ) = @_;
    my $out = '';
    $out .= $self->render_label($rargs);
    $out .= $self->render_element($rargs);
    $out .= $self->render_errors($rargs);
    return $out;
}

sub layout_simple {
    my ( $self, $rargs ) = @_;
    my $out = qq{\n<div };
    $out .= $self->_render_attrs( $rargs->{wrapper} );
    $out .= qq{>};
    $out .= $self->layout_bare($rargs);
    $out .= qq{\n</div>};
}

sub layout_w_errs {
    my ( $self, $rargs ) = @_;
    my $out = '';
    $out .= $self->render_element($rargs);
    $out .= $self->render_errors($rargs);
    return $out;
}

sub localize {
   my ( $self, @message ) = @_;
   return $self->localizer->loc_($message[0]);
}


sub render_form {
    my ($self, $rargs, $fields ) = @_;

    my $out = '';
    $out .= $self->render_start($rargs);

    foreach my $field ( @$fields ) {
        $out .= $field->render;
    }

    $out .= $self->render_end($rargs);
    return $out;
}

sub render_start {
    my ($self, $rargs ) = @_;

    my $out = qq{<form };
    $out .= q{>};
}

sub render_end {
    my ($self, $rargs ) = @_;

   return q{</form>};
}

sub render_field {
  my ( $self, $rargs ) = @_;

  my $layout = $rargs->{layout} || 'simple';
  my $meth = $self->layouts->{$layout};
  my $out;
  if ( $meth ) {
    $out .= $meth->($self, $rargs);
  }
  else {
    die "layout $layout not found";
  }
  return $out;
}

=head2 render_input

=cut

sub render_input {
  my ( $self, $rargs ) = @_;

  my $input_type = $rargs->{input_type};
  # checkboxes are special
  return $self->render_checkbox($rargs) if $input_type eq 'checkbox';

  my $name = $rargs->{name};
  my $id = $rargs->{name};
  my $fif = $rargs->{fif};

  my $out = qq{\n<input type="$input_type" };
  $out .= qq{name="$name" };
  $out .= qq{id="$id" };
  $out .= qq{value="$fif" };
  $out .= $self->_render_attrs( $rargs->{element}, scalar @{$rargs->{errors}} );
  $out .= "/>";
  return $out;
}

=head2 _render_attrs

=cut

sub _render_attrs {
  my ($self, $attrs, $has_errors) = @_;
  my $out = $self->_render_class( $attrs->{class}, $has_errors);
  while ( my ( $attr, $value ) =  each  %$attrs ) {
    next if $attr eq 'class';  # handled separately
    $out .= qq{$attr="$value" };
  }
  return $out;
}

=head2 _render_class

=cut

sub _render_class {
  my ( $self, $class, $has_errors ) = @_;

  $class ||= [];
  $class = [split(' ', $class)] unless ref $class eq 'ARRAY';
  push @$class, 'error' if $has_errors;
  my $out = '';
  if ( @$class ) {
    my $classes = join(' ', @$class);
    $out = qq{class="$classes" };
  }
  return $out;
}

=head2 render_select

=cut

sub render_select {
  my ( $self, $rargs ) = @_;

  my $id = $rargs->{id};
  my $name = $rargs->{name};

  # beginning of select
  my $out = qq{\n<select };
  $out .= qq{name="$name" };
  $out .= qq{id="$id" };
  $out .= qq{multiple="multiple" } if $rargs->{multiple};
  $out .= $self->_render_attrs( $rargs->{element}, scalar @{$rargs->{errors}} );
  $out .= ">";

  # render empty_select
  if ( exists $rargs->{empty_select} ) {
    my $label = $self->localize($rargs->{empty_select});
    $out .= qq{\n<option value="">$label</option>};
  }

  # render options
  my $options = $rargs->{options};
  foreach my $option ( @$options ) {
    my $value = $option->{value};
    my $label = $option->{label};
    $out .= qq{\n<option value="$value">$label</option>};
  }

  # end of select
  $out .= "\n</select>\n";
  return $out;
}

=head2 render_checkbox

=cut

sub render_checkbox {
  my ( $self, $rargs ) = @_;

  my $name = $rargs->{name};
  my $id = $rargs->{name};
  my $checkbox_value = $rargs->{checkbox_value};
  my $fif = $rargs->{fif};

  my $out = qq{\n<input };
  $out .= qq{type="checkbox" };
  $out .= qq{name="$name" };
  $out .= qq{id="$id" };
  $out .= qq{value="$checkbox_value" };
  $out .= qq{checked="checked" } if $fif eq $checkbox_value;
  $out .= $self->_render_attrs( $rargs->{element}, scalar @{$rargs->{errors}} );
  $out .= "/>";
  return $out;
}

=head2 render_textarea

=cut

sub render_textarea {
  my ( $self, $rargs ) = @_;

  my $name = $rargs->{name};
  my $id = $rargs->{id};
  my $fif = $rargs->{fif};

  my $out = "\n<textarea ";
  $out .= qq{name="$name" };
  $out .= qq{id="$id" };
  $out .= $self->_render_attrs( $rargs->{element}, scalar @{$rargs->{errors}} );
  $out .= ">$fif</textarea>";
  return $out;
}

=head2 render_element

=cut

sub render_element {
  my ( $self, $rargs ) = @_;

  my $form_element = $rargs->{form_element};
  my $meth = "render_$form_element";
  return $self->$meth($rargs);
}

=head2 render_label

=cut

sub render_label {
  my ( $self, $rargs ) = @_;

  my $id = $rargs->{id};
  my $label = $self->localize($rargs->{label});
  my $out = qq{\n<label for="$id">$label</label>};
  return $out
}

=head2 render_errors

=cut

sub render_errors {
  my ( $self, $rargs ) = @_;

  my $errors = $rargs->{errors} || [];
  my $out = '';
  foreach my $error (@$errors) {
    $out .= qq{\n<span>$error</span>};
  }
  return $out;
}

sub default_html_filter {
    my $string = shift;
    return '' if (!defined $string);
    $string =~ s/&/&amp;/g;
    $string =~ s/</&lt;/g;
    $string =~ s/>/&gt;/g;
    $string =~ s/"/&quot;/g;
    return $string;
}

1;
