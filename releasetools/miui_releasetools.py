
import common
import copy

def FullOTA_Assertions(info):
  info.script.Mount("/data")

def IncrementalOTA_Assertions(info):
  info.script.Mount("/data")

def FullOTA_InstallEnd(info):
  UnpackData(info.script)
  CopyDataFiles(info.input_zip, info.output_zip, info.script)
  Relink(info.input_zip, info.output_zip, info.script)
  SetPermissions(info.script)
  RemoveAbandonedPreinstall(info.script)


def IncrementalOTA_InstallEnd(info):
  UnpackData(info.script)
  Relink(info.target_zip, info.output_zip, info.script)
  SetPermissions(info.script)
  RemoveAbandonedPreinstall(info.script)



def Relink(input_zip, output_zip, script):
  """relink tool to rebuilding cust variant file and cust link
for backward compatibility that update with ota"""

  print "[MIUI CUST] OTA: handle relink"
  # copy relink
  data = input_zip.read("OTA/bin/relink")
  common.ZipWriteStr(output_zip, "META-INF/com/miui/relink", data)
  # add to script
  script.AppendExtra("package_extract_file(\"META-INF/com/miui/relink\", \"/tmp/relink\");")
  script.AppendExtra("set_perm(0, 0, 0555, \"/tmp/relink\");")
  script.AppendExtra("run_program(\"/tmp/relink\");")
  script.AppendExtra("delete(\"/tmp/relink\");")


def CopyDataFiles(input_zip, output_zip, script):
  """Copies files underneath data/miui in the input zip to the output zip."""

  print "[MIUI CUST] OTA: copy data files"
  for info in input_zip.infolist():
    if info.filename.startswith("DATA/miui/"):
      basefilename = info.filename[5:]
      info2 = copy.copy(info)
      info2.filename = "data/" + basefilename
      data = input_zip.read(info.filename)
      output_zip.writestr(info2, data)
  #common.ZipWriteStr(output_zip, "data/miui/reinstall_apps", "reinstall_apps")
  #script.AppendExtra("set_perm(1000, 1000, 0666, \"/data/miui/reinstall_apps\");")


def UnpackData(script):
  script.UnpackPackageDir("data", "/data")


def SetPermissions(script):
  print "[MIUI CUST] OTA: SetPermissions"
  SetPermissionsRecursive(script, "/data/miui", 1000, 1000, 0755, 0644)
  script.AppendExtra("set_metadata(\"/system/bin/debuggerd\", \"uid\", 0, \"gid\", 2000, \"mode\", 0755, \"capabilities\", 0x0, \"selabel\", \"u:object_r:system_file:s0\");")
  script.AppendExtra("set_metadata(\"/system/bin/debuggerd_vendor\", \"uid\", 0, \"gid\", 2000, \"mode\", 0755, \"capabilities\", 0x0, \"selabel\", \"u:object_r:debuggerd_exec:s0\");")
  script.AppendExtra("set_metadata(\"/system/xbin/su\", \"uid\", 0, \"gid\", 2000, \"mode\", 06755, \"capabilities\", 0x0, \"selabel\", \"u:object_r:su_exec:s0\");")


def SetPermissionsRecursive(script, d, gid, uid, dmod, fmod):
  try:
    script.SetPermissionsRecursive(d, gid, uid, dmod, fmod)
  except TypeError:
    script.SetPermissionsRecursive(d, gid, uid, dmod, fmod, None, None)


def RemoveAbandonedPreinstall(script):
  script.AppendExtra("delete_recursive(\"/data/miui/preinstall_apps\");")
  script.AppendExtra("delete_recursive(\"/data/miui/cust/preinstall_apps\");")

