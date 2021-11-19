local IpcManagerCore = {}
local ffi = require('ffi')
require('common')
require('win32types')
--print(ffi.C.CreateFileMappingA)
ffi.cdef[[
	unsigned long GetLastError();
	void* CreateFileA(
		const char* lpFileName,
		unsigned long dwDesiredAccess,
		unsigned long dwShareMode,
		void* lpSecurityAttributes,
		unsigned long dwCreationDisposition,
		unsigned long dwFlagsAndAttributes,
		void* hTemplateFile
	);
	unsigned long GetFileSize(
		void* hFile,
		unsigned long* lpFileSizeHigh
	);
	long WriteFile(
		void* hFile,
		void* lpBuffer,
		unsigned long nNumberOfBytesToWrite,
		unsigned long* lpNumberOfBytesWritten,
		void* lpOverlapped
	);
	unsigned long SetFilePointer(
		void* hFile,
		long lDistanceToMove,
		long* lpDistanceToMoveHigh,
		unsigned long dwMoveMethod
	);
	void* CreateFileMappingA(
		void* hFile,
		void* lpAttributes,
		unsigned long flProtect,
		unsigned long dwMaximumSizeHigh,
		unsigned long dwMaximumSizeLow,
		const char* lpName
	);
    void* OpenFileMappingA(
        unsigned long flProtect,
        bool inheritHandle,
        const char* lpName
    );
	void* MapViewOfFile(
		void* hFileMappingObject,
		unsigned long dwDesiredAccess,
		unsigned long dwFileOffsetHigh,
		unsigned long dwFileOffsetLow,
		size_t dwNumberOfBytesToMap
	);
	long UnmapViewOfFile(void* lpBaseAddress);
	long CloseHandle(void* hObject);
	long DeleteFileA(const char* lpFileName);
]];

local C = ffi.C

local ERROR_ALREADY_EXISTS = 183
local GENERIC_READ  = 0x80000000
local GENERIC_WRITE = 0x40000000
local OPEN_ALWAYS   = 4
local FILE_ATTRIBUTE_ARCHIVE = 0x20
local FILE_FLAG_RANDOM_ACCESS = 0x10000000
local FILE_BEGIN = 0
local PAGE_READWRITE = 0x4
local FILE_MAP_ALL_ACCESS = 0xf001f

IpcManagerCore["MappedFile"] = {}
IpcManagerCore["MappedFile"]["FileName"] = "Global\\BPMMF"
IpcManagerCore["MappedFile"]["MapName"] = "BPMMFShared"
IpcManagerCore["MappedFile"]["FileHandle"] = nil
IpcManagerCore["MappedFile"]["MemoryHandle"] = nil
IpcManagerCore["MappedFile"]["MappedView"] = nil
IpcManagerCore["MappedFile"]["DesiredSize"] = 8

--ipc struct
--0x0:0x3 - TargetId
--0x4:0x7- TargetIndex 

function IpcManagerCore.Get()

    local ipcStruct = {
        ["TargetId"] = 0,
        ["TargetIndex"] = 0,
    }

    function IpcManagerCore:CreateMappedFile()
        local fileName = self["MappedFile"]["FileName"]
        local cStrName = ffi.new("char[?]", #fileName+1)
        local cStrMapName = ffi.new("char[?]", #self["MappedFile"]["MapName"]+1)
        ffi.copy(cStrName, fileName)
        ffi.copy(cStrMapName, self["MappedFile"]["MapName"])
        self["MappedFile"]["FileHandle"] = ffi.C.CreateFileA(cStrName, bit.bor(GENERIC_READ, GENERIC_WRITE), bit.bor(0x00000001, 0x00000002), 
        nil, OPEN_ALWAYS, bit.bor(FILE_ATTRIBUTE_ARCHIVE, FILE_FLAG_RANDOM_ACCESS), nil)
        
        if(self["MappedFile"]["FileHandle"] == nil)then
            print("[IpcManager] File handle was null!")
            return
        end
        self["MappedFile"]["DesiredSize"] = 8

        local fileExists = C.GetLastError() == ERROR_ALREADY_EXISTS
        --print(C.GetLastError())
        if(fileExists)then
            local fileSize = C.GetFileSize(self["MappedFile"]["FileHandle"], nil)
            if(fileSize == 0)then
                fileExists = false
                self["MappedFile"]["DesiredSize"] = 8
            else
                self["MappedFile"]["DesiredSize"] = fileSize
            end
        else
            self["MappedFile"]["DesiredSize"] = 8
        end

        self["MappedFile"]["MemoryHandle"] = ffi.C.CreateFileMappingA(self["MappedFile"]["FileHandle"], nil, 0x40, 0, self["MappedFile"]["DesiredSize"], cStrName)
        print(("[IpcManager] Memory mapping handle [%s]"):fmt(self["MappedFile"]["MemoryHandle"]))

        self["MappedFile"]["MappedView"] = ffi.C.MapViewOfFile(self["MappedFile"]["MemoryHandle"], FILE_MAP_ALL_ACCESS, 0, 0, 0)
        print(("[IpcManager] Mapped view [%s]"):fmt(self["MappedFile"]["MappedView"]))

    end

    function IpcManagerCore:DisposeUnmanaged()
        ffi.C.UnmapViewOfFile(self["MappedFile"]["MappedView"])
        ffi.C.CloseHandle(self["MappedFile"]["MemoryHandle"])
        ffi.C.CloseHandle(self["MappedFile"]["FileHandle"])
    end

    function IpcManagerCore:SetMappedTargetId(targetId)
        if(targetId ~= ipcStruct["TargetId"])then
            ipcStruct["TargetId"] = targetId
            local buffer = ffi.new("uint32_t[?]", 2)
            buffer[0] = targetId
            ffi.copy(self["MappedFile"]["MappedView"], buffer, self["MappedFile"]["DesiredSize"])
            local bytesWritten = ffi.new("long*")
            local overlapped = ffi.new("void*")
            local writefile = ffi.C.WriteFile(self["MappedFile"]["FileHandle"], buffer, self["MappedFile"]["DesiredSize"], bytesWritten, overlapped)
        end
    end

    function IpcManagerCore:SetMappedTargetIndex(targetIndex)
        if(targetIndex ~= ipcStruct["TargetIndex"])then
            print(("Setting new indx [%s]"):fmt(targetIndex))
            ipcStruct["TargetIndex"] = targetIndex
            local buffer = ffi.new("uint32_t[?]", 2)
            buffer[1] = targetIndex
            ffi.copy(self["MappedFile"]["MappedView"], buffer, self["MappedFile"]["DesiredSize"])
            local bytesWritten = ffi.new("long*")
            local overlapped = ffi.new("void*")
            local writefile = ffi.C.WriteFile(self["MappedFile"]["FileHandle"], buffer, self["MappedFile"]["DesiredSize"], bytesWritten, overlapped)
        end
    end

    function IpcManagerCore:GetMappedTargetId()
        return ipcStruct["TargetId"]
    end

    function IpcManagerCore:GetMappedTargetIndex()
        return ipcStruct["TargetIndex"]
    end

    function IpcManagerCore:CheckChanges()
        local buffer = ffi.new("uint32_t[?]", 2)
      --  self["MappedFile"]["MappedView"] = ffi.C.MapViewOfFile(self["MappedFile"]["MemoryHandle"], FILE_MAP_ALL_ACCESS, 0, 0, 0)
        ffi.copy(buffer, self["MappedFile"]["MappedView"], self["MappedFile"]["DesiredSize"])
        if(buffer[0] ~= ipcStruct["TargetId"])then
            print(("New target [%s]"):fmt(buffer[0]))
            ipcStruct["TargetId"] = buffer[0]
        elseif(buffer[1] ~= ipcStruct["TargetIndex"])then
            print(("new index [%s]"):fmt(buffer[1]))
            ipcStruct["TargetIndex"] = buffer[1]
        end
    end

    return IpcManagerCore

end

return IpcManagerCore.Get()