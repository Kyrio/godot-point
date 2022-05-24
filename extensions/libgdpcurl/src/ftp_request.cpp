#include "ftp_request.h"

#include <string>
#include <godot_cpp/classes/engine.hpp>
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

    curl_easy_reset(curl);

    curl_easy_setopt(curl, CURLOPT_URL, url.utf8().get_data());
    curl_easy_setopt(curl, CURLOPT_DIRLISTONLY, 1L);
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, FtpRequest::list_callback);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, this);
    CURLcode response = curl_easy_perform(curl);

    if (response == CURLE_OK) {
        return Error::OK;
    }

    return Error::ERR_CANT_CONNECT;
}

int FtpRequest::request_info(const String &url) {
    if (!curl) {
        return Error::ERR_UNCONFIGURED;
    }

    long filetime = -1;

    curl_easy_reset(curl);

    curl_easy_setopt(curl, CURLOPT_URL, url.utf8().get_data());
    curl_easy_setopt(curl, CURLOPT_NOBODY, 1L);
    curl_easy_setopt(curl, CURLOPT_FILETIME, 1L);
    curl_easy_setopt(curl, CURLOPT_HEADERFUNCTION, FtpRequest::throwaway_callback);
    curl_easy_setopt(curl, CURLOPT_HEADER, 0L);

    CURLcode response = curl_easy_perform(curl);

    if (response == CURLE_OK) {
        response = curl_easy_getinfo(curl, CURLINFO_FILETIME, &filetime);
        emit_signal("info_request_completed", response, filetime);

        return Error::OK;
    }

    return Error::ERR_CANT_CONNECT;
}

size_t FtpRequest::list_callback(char *data, size_t size, size_t length, FtpRequest *userdata) {
    size_t real_size = size * length;

    std::string data_string(data, real_size);
    String body(data_string.c_str());
    
    userdata->emit_signal("list_request_completed", body);

    return real_size;
}

size_t FtpRequest::throwaway_callback(char *data, size_t size, size_t length, void *userdata) {
    size_t real_size = size * length;
    return real_size;
}

void FtpRequest::_bind_methods() {
	ClassDB::bind_method(D_METHOD("request_list"), &FtpRequest::request_list);
	ClassDB::bind_method(D_METHOD("request_info"), &FtpRequest::request_info);

	ADD_SIGNAL(MethodInfo("list_request_completed", PropertyInfo(Variant::STRING, "body")));
	ADD_SIGNAL(MethodInfo("info_request_completed", PropertyInfo(Variant::INT, "curlcode"), PropertyInfo(Variant::INT, "filetime")));
}
