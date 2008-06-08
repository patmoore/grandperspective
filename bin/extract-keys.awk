# Extracts the key string values from (files formatted as) .strings files.
#
# For example, for the following line:
#
#   "Hello world" = "Hallo wereld";
#
# it will output "Hello world" (without the quotes).

$0 ~ /".*" *= *".*";/ {
  # The line assigns a string value to a key value.

  if ( match($0, "\"") ) {
    quote_pos = RSTART;

    if ( match($0, "\" *= *\"") ) {
      # Output the key, without the surrounding quotes

      print substr($0, quote_pos + 1, RSTART - quote_pos - 1);
    }
  }
}
