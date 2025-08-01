export type SerializerConstructor = ((Buffer: buffer?, Size: number?, ProfilerTags: boolean?) -> (Serializer))

export type Serializer = {
    --- Writes an unsigned integer of the given length in bits.
    WriteUInt: ((Bits: number, Value: number) -> ());
    --- Reads an unsigned integer of the given length in bits.
    ReadUInt: ((Bits: number) -> (number));

    --- Writes a signed integer of the given length in bits.
    WriteInt: ((Bits: number, Value: number) -> ());
    --- Reads a signed integer of the given length in bits.
    ReadInt: ((Bits: number) -> (number));

    --- Writes a floating point number of the given length in bits.
    WriteFloat: ((Bits: number, Value: number) -> ());
    --- Reads a floating point number of the given length in bits.
    ReadFloat: ((Bits: number) -> (number));

    --- Copies the contents a buffer to this serializer's buffer between the given positions.
    WriteBuffer: ((Subject: buffer, From: number, To: number) -> ());
    --- Reads a buffer of the given length in bits.
    ReadBuffer: ((LengthBits: number) -> (buffer));

    --- Writes a string of the given length in bits.
    WriteString: ((Value: string, LengthBits: number) -> ());
    --- Reads a string of the given length in bits.
    ReadString: ((Length: number) -> (string));

    --- Increments the current position in bits by the given amount.
    IncrementPosition: ((ByBits: number) -> ());
    --- Sets the current position in bits.
    SetPosition: ((Bit: number) -> ());
    --- Gets the current position in bits.
    GetPosition: (() -> (number));
    --- Extends the current buffer by the given number of bits if deemed necessary.
    Extend: ((ByBits: number) -> ());
    --- Aligns the current position to the start of the next byte.
    Align: (() -> ());

    --- Creates a new buffer fitted to the current position.
    GetClippedBuffer: (() -> (buffer));
    --- Obtains the raw internal buffer including the unused space.
    GetBuffer: (() -> (buffer));
    --- Sets the internal buffer to the given buffer.
    SetBuffer: ((Buffer: buffer, FromBit: number, ToBit: number) -> ());

    --- Optional debug context callback for human-readable serialization debugging or performance profiling.
    Context: ((Name: string?) -> ())?;

    Constructor: SerializerConstructor;
    Type: string;
}

return {}