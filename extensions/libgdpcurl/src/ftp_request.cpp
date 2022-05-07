#include "ftp_request.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include <curl/curl.h>

using namespace godot;

FtpRequest::FtpRequest() {
    CURL *curl = curl_easy_init();

    if (curl) {
        UtilityFunctions::print("Curl initialized.");
        curl_easy_cleanup(curl);
    }

    UtilityFunctions::print("FtpRequest created.");
}

FtpRequest::~FtpRequest() {
    UtilityFunctions::print("FtpRequest destroyed.");
}

void FtpRequest::_bind_methods() {
}
