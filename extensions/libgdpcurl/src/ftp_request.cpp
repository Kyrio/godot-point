#include "ftp_request.h"

#include <string>
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

FTPRequest::FTPRequest() {
    curl = curl_easy_init();
}

FTPRequest::~FTPRequest() {
    if (curl) {
        curl_easy_cleanup(curl);
    }
}

int FTPRequest::request_list(const String &url) {
    if (!curl) {
        return Error::ERR_UNCONFIGURED;
    }

    curl_easy_reset(curl);

    curl_easy_setopt(curl, CURLOPT_URL, url.utf8().get_data());
    curl_easy_setopt(curl, CURLOPT_DIRLISTONLY, 1L);
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, FTPRequest::list_callback);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, this);

    return curl_easy_perform(curl);
}

int FTPRequest::request_filetime(const String &url) {
    if (!curl) {
        return Error::ERR_UNCONFIGURED;
    }

    long filetime = -1;

    curl_easy_reset(curl);

    curl_easy_setopt(curl, CURLOPT_URL, url.utf8().get_data());
    curl_easy_setopt(curl, CURLOPT_NOBODY, 1L);
    curl_easy_setopt(curl, CURLOPT_FILETIME, 1L);
    curl_easy_setopt(curl, CURLOPT_HEADERFUNCTION, FTPRequest::throwaway_callback);
    curl_easy_setopt(curl, CURLOPT_HEADER, 0L);

    CURLcode response = curl_easy_perform(curl);

    if (response == CURLE_OK) {
        response = curl_easy_getinfo(curl, CURLINFO_FILETIME, &filetime);
        latest_filetime = filetime;
        return response;
    }

    return response;
}

String FTPRequest::get_list() {
    return latest_list;
}

int64_t FTPRequest::get_filetime() {
    return latest_filetime;
}

size_t FTPRequest::list_callback(char *data, size_t size, size_t length, FTPRequest *userdata) {
    size_t real_size = size * length;

    std::string data_string(data, real_size);
    userdata->latest_list = String(data_string.c_str());

    return real_size;
}

size_t FTPRequest::throwaway_callback(char *data, size_t size, size_t length, void *userdata) {
    size_t real_size = size * length;
    return real_size;
}

void FTPRequest::_bind_methods() {
	ClassDB::bind_method(D_METHOD("request_list"), &FTPRequest::request_list);
	ClassDB::bind_method(D_METHOD("request_filetime"), &FTPRequest::request_filetime);
	ClassDB::bind_method(D_METHOD("get_list"), &FTPRequest::get_list);
	ClassDB::bind_method(D_METHOD("get_filetime"), &FTPRequest::get_filetime);
}
