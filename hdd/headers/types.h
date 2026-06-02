typedef unsigned char byte;
typedef unsigned char  u8;
typedef unsigned short u16;
typedef unsigned int   u32;

typedef struct DirectoryEntry {
    char filename[11];
    u8 attribute;
    u8 reserved;
    u8 millisecond;
    u16 createTime;
    u16 createDate;
    u16 accessDate;
    u16 reserved2;
    u16 writeTime;
    u16 writeDate;
    u16 startCluster;
    u32 size;
} DirectoryEntry;

