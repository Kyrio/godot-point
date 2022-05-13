#include "ftp_request.h"

#include <string>
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/http_request.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

FtpRequest::FtpRequest() {
    curl = curl_easy_init();
}

FtpRequest::~FtpRequest() {
    if (curl) {
        curl_easy_cleanup(curl);
    }
}

int FtpRequest::request_list(const String &url) {
    if (!curl) {
        return Error::ERR_UNCONFIGURED;
    }

    curl_easy_setopt(curl, CURLOPT_URL, url.utf8().get_data());
    curl_easy_setopt(curl, CURLOPT_DIRLISTONLY, 1L);
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, FtpRequest::write_callback);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, this);
    CURLcode response = curl_easy_perform(curl);

    if (response == CURLE_OK) {
        return Error::OK;
    }

    return Error::ERR_CANT_CONNECT;
}

size_t FtpRequest::write_callback(char *data, size_t size, size_t length, FtpRequest *userdata) {
    size_t real_size = size * length;

    std::string data_string(data, real_size);
    String body(data_string.c_str());
    
    userdata->emit_signal("request_completed", HTTPRequest::Result::RESULT_SUCCESS, body);

    return real_size;
}

void FtpRequest::_bind_methods() {
	ClassDB::bind_method(D_METHOD("request_list"), &FtpRequest::request_list);

	ADD_SIGNAL(MethodInfo("request_completed", PropertyInfo(Variant::INT, "result"), PropertyInfo(Variant::STRING, "body")));
}
