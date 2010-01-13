#n
/^\/\*/, /";$/ {  # The lines to possibly omit.
  H
  x
  /";$/! {      # This is not the end yet.
    # Move lines back to hold space.
    x
    d
  }
  /"";$/! {     # String is not empty
    # So don't omit these lines.
    p
  }
  # Empty the hold space.
  s/.*//
  x
}
