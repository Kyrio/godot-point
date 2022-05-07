#ifndef FTP_REQUEST_H
#define FTP_REQUEST_H

#include <godot_cpp/classes/node.hpp>

namespace godot {
    class FtpRequest : public Node {
        GDCLASS(FtpRequest, Node)

    protected:
        static void _bind_methods();

    public:
        FtpRequest();
        ~FtpRequest();
    };
}

#endif
