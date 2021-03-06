#ifndef FTP_REQUEST_H
#define FTP_REQUEST_H

#include <curl/curl.h>

#include <godot_cpp/classes/global_constants.hpp>
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/variant/string.hpp>

using namespace godot;

class FTPRequest : public Node {
    GDCLASS(FTPRequest, Node)

private:
    CURL *curl;

    String latest_list;
    int64_t latest_filetime; 

    static size_t list_callback(char *data, size_t size, size_t length, FTPRequest *userdata);
    static size_t throwaway_callback(char *data, size_t size, size_t length, void *userdata);

protected:
    static void _bind_methods();

public:
    FTPRequest();
    ~FTPRequest();

    int request_list(const String &url);
    int request_filetime(const String &url);

    String get_list();
    int64_t get_filetime();
};

#endif
