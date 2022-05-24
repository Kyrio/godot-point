#ifndef FTP_REQUEST_H
#define FTP_REQUEST_H

#include <curl/curl.h>

#include <godot_cpp/classes/global_constants.hpp>
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/variant/string.hpp>

using namespace godot;

class FtpRequest : public Node {
    GDCLASS(FtpRequest, Node)

private:
    CURL *curl;

    static size_t list_callback(char *data, size_t size, size_t length, FtpRequest *userdata);
    static size_t throwaway_callback(char *data, size_t size, size_t length, void *userdata);

protected:
    static void _bind_methods();

public:
    FtpRequest();
    ~FtpRequest();

    int request_list(const String &url);
    int request_info(const String &url);
};

#endif
