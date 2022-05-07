#include "ftp_request.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

FtpRequest::FtpRequest() {
    UtilityFunctions::print("FtpRequest created.");
}

FtpRequest::~FtpRequest() {
    UtilityFunctions::print("FtpRequest destroyed.");
}

void FtpRequest::_bind_methods() {
}
