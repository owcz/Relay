/***
  Copyright (C) 2011-2012 Application Name Developers
  This program is free software: you can redistribute it and/or modify it
  under the terms of the GNU Lesser General Public License version 3, as published
  by the Free Software Foundation.

  This program is distributed in the hope that it will be useful, but
  WITHOUT ANY WARRANTY; without even the implied warranties of
  MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
  PURPOSE. See the GNU General Public License for more details.

  You should have received a copy of the GNU General Public License along
  with this program. If not, see
***/

using GLib;
using Gee;

public class Message : GLib.Object {
    public string? message { get; set; }
    public string prefix { get; set; }
    public string command { get; set; }
    public string[] parameters { get; set; }
    public string user_name = "";
    public bool internal = false;
    public bool usr_private_message = false;
    private static Regex? regex;
    private static Regex? fix_message;

    private static const string regex_string = """^(:(?<prefix>\S+) )?(?<command>\S+)( (?!:)(?<params>.+?))?( :(?<trail>.+))?$""";
    private static const string replace_string = """\\0[0-9][0-9]""";
    
    public Message (string _message = "") {
        if (regex == null) {
            try{
                regex = new Regex(regex_string, RegexCompileFlags.OPTIMIZE );
                fix_message = new Regex(replace_string, RegexCompileFlags.OPTIMIZE );
            }catch(RegexError e){
                error("There was a regex error that should never happen");
            }
        }
        if (_message.length == 0)
            return;

        message = _message.escape("\b\f\n\r\t\\\"");
        message = fix_message.replace_literal(message, message.length, 0, "");
        parse_regex();
    }

    public string get_prefix_name () {
        if (prefix.index_of_char('!') == -1)
            return "";
        if (command == IRC.PRIVATE_MESSAGE)
            usr_private_message = true;
        return prefix.split("!")[0];
    }

    public void user_name_set (string name) { user_name = name;
    }

    //Use this function to add padding to the user name
    public string user_name_get () {
		string name = user_name;
		if (name.length >= IRC.USER_LENGTH) 
			name = user_name.substring(0, IRC.USER_LENGTH - 4) + "...";
        int length = IRC.USER_LENGTH - name.length;
        return name + string.nfill(length, ' ');
    }

    public void parse_regex () {
        try{
            regex.replace_eval (message, -1, 0, 0, (mi, s) => {
                prefix = mi.fetch_named ("prefix");
                command = mi.fetch_named ("command");
                parameters = mi.fetch_named ("params").split(" ") ;
                message = mi.fetch_named ("trail");
                
                if(message != null)
                    message = message.replace("\t", "");
                
                if(command == IRC.PRIVATE_MESSAGE)
                    user_name_set(prefix.split("!")[0]);
                
                return false;
            });
        }catch (RegexError e){
            warning("Regex error with " + message);
        }
    }




}
