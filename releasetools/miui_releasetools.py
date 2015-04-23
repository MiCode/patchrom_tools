
import common
import copy
import edify_generator

def FullOTA_Assertions(info):
  info.script.Mount("/data")

def IncrementalOTA_Assertions(info):
  info.script.Mount("/data")

def PushBusybox(input_zip, output_zip, script):
  try:
    data = input_zip.read("OTA/bin/busybox")
    common.ZipWriteStr(output_zip, "META-INF/com/miui/busybox", data)
    script.AppendExtra("package_extract_file(\"META-INF/com/miui/busybox\", \"/tmp/busybox\");")
    script.SetPermissions("/tmp/busybox", 0, 0, 0555, None, None)
  except KeyError:
    print 'Ignore replace cert'

def RemoveUseslessFiles(script):
  script.DeleteFiles(["/tmp/busybox"])

def ProcessSystemFormat(info):
  edify = info.script
  script_temp = edify_generator.EdifyGenerator(3, info.script.info)
  PushBusybox(info.input_zip, info.output_zip, script_temp)
  script_temp.AppendExtra("run_program(\"/tmp/busybox\", \"rm\", \"-rf\", \"/system\");")
  script_temp_str = "".join(script_temp.script).replace(";", ";\n").strip()
  format_system_line = 0
  mount_system_line = 0
  for i in xrange(len(edify.script)):
    if format_system_line > 0 and mount_system_line > 0:
      break
    if ");" in edify.script[i] and "format" in edify.script[i] and "/system" in edify.script[i]:
      format_system_line = i
      continue
    elif ");" in edify.script[i] and "mount" in edify.script[i] and "/system" in edify.script[i]:
      mount_system_line = i
      continue
  if mount_system_line > format_system_line > 0:
    edify.script[format_system_line] = edify.script[format_system_line].replace(edify.script[format_system_line], edify.script[mount_system_line])
    edify.script[mount_system_line] = edify.script[mount_system_line].replace(edify.script[mount_system_line] , script_temp_str)
  elif format_system_line > mount_system_line > 0:
    edify.script[format_system_line] = edify.script[format_system_line].replace(edify.script[format_system_line], "")
    edify.script[mount_system_line] = edify.script[mount_system_line].replace(";", ";\n" + script_temp_str)
  else:
    PushBusybox(info.input_zip, info.output_zip, info.script)

def FullOTA_InstallEnd(info):
  UnpackData(info.script)
  CopyDataFiles(info.input_zip, info.output_zip, info.script)
  ProcessSystemFormat(info)
  Replace_Cert(info.input_zip, info.output_zip, info.script)
  RemoveUseslessFiles(info.script)
  SetPermissions(info.script)
  RemoveAbandonedPreinstall(info.script)


def IncrementalOTA_InstallEnd(info):
  UnpackData(info.script)
  Replace_Cert(info.target_zip, info.output_zip, info.script)
  SetPermissions(info.script)
  RemoveAbandonedPreinstall(info.script)

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


def UnpackData(script):
  script.UnpackPackageDir("data", "/data")


def SetPermissions(script):
  print "[MIUI CUST] OTA: SetPermissions"
  SetPermissionsRecursive(script, "/data/miui", 1000, 1000, 0755, 0644)


def SetPermissionsRecursive(script, d, gid, uid, dmod, fmod):
  try:
    script.SetPermissionsRecursive(d, gid, uid, dmod, fmod)
  except TypeError:
    script.SetPermissionsRecursive(d, gid, uid, dmod, fmod, None, None)


def RemoveAbandonedPreinstall(script):
  script.AppendExtra("delete_recursive(\"/data/miui/preinstall_apps\");")
  script.AppendExtra("delete_recursive(\"/data/miui/cust/preinstall_apps\");")

def Replace_Cert(input_zip, output_zip, script):
  try:
    data = input_zip.read("OTA/bin/replace_key")
    common.ZipWriteStr(output_zip, "META-INF/com/miui/replace_key", data)
    script.AppendExtra("package_extract_file(\"META-INF/com/miui/replace_key\", \"/tmp/replace_key\");")
    script.SetPermissions("/tmp/replace_key", 0, 0, 0555, None, None)
    script.AppendExtra("run_program(\"/sbin/sh\", \"/tmp/replace_key\");")
    script.DeleteFiles(["/tmp/replace_key"])
  except KeyError:
    print 'Ignore replace cert'

