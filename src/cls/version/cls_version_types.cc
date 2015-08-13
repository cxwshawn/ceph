
#include "cls/version/cls_version_types.h"
#include "common/Formatter.h"
#include "common/ceph_json.h"

void obj_version::decode_json(JSONObj *obj)
{
  JSONDecoder::decode_json("ver", ver, obj);
  JSONDecoder::decode_json("tag", tag, obj);
}

