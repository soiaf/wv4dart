library wvbitutils;

import "types.dart";

class BitsUtils
{
    static Bitstream getbit(Bitstream bs)
    {
        int uns_buf = 0;

        if (bs.bc > 0)
        {
            bs.bc--;
        }
        else
        {
            bs.ptr++;
            bs.buf_index++;
            bs.bc = 7;

            if (bs.ptr == bs.end)
            {
                // wrap call here
                bs = bs_read(bs);
            }
            uns_buf = bs.buf[bs.buf_index] & 0xff;
            bs.sr = uns_buf;
        }

        if ((bs.sr & 1) > 0)
        {
            bs.sr = bs.sr >> 1;
            bs.bitval = 1;
            return bs;
        }
        else
        {
            bs.sr = bs.sr >> 1;
            bs.bitval = 0;
            return bs;
        }
    }

    static int getbits(int nbits, Bitstream bs)
    {
        int uns_buf;
        int value;

        while ((nbits) > bs.bc)
        {
            bs.ptr++;
            bs.buf_index++;

            if (bs.ptr == bs.end)
            {
                bs = bs_read(bs);
            }
            uns_buf = bs.buf[bs.buf_index] & 0xff;
            bs.sr = bs.sr | (uns_buf << bs.bc); // values in buffer must be unsigned
            bs.bc += 8;
        }

        value = bs.sr;

        if (bs.bc > 32)
        {
            bs.bc -= (nbits);
            bs.sr = (bs.buf[bs.buf_index] & 0xff) >> (8 - bs.bc);
        }
        else
        {
            bs.bc -= (nbits);
            bs.sr >>= (nbits);
        }

        return (value);
    }

    static Bitstream bs_open_read(List<num> stream, int buffer_start, int buffer_end, StreamedFile file,
        int file_bytes, int passed)
    {
        //   CLEAR (*bs);
        Bitstream bs = new Bitstream();

        bs.buf = stream;
        bs.buf_index = buffer_start;
        bs.end = buffer_end;
        bs.sr = 0;
        bs.bc = 0;

        if (passed != 0)
        {
            bs.ptr = bs.end - 1;
            bs.file_bytes = file_bytes;
            bs.file = file;
        }
        else
        {
            /* Strange to set an index to -1, but the very first call to getbit will iterate this */
            bs.buf_index = -1;
            bs.ptr = -1;
        }

        return bs;
    }

    static Bitstream bs_read(Bitstream bs)
    {
        if (bs.file_bytes > 0)
        {
            int bytes_read, bytes_to_read;

            bytes_to_read = Defines.BITSTREAM_BUFFER_SIZE;

            if (bytes_to_read > bs.file_bytes)
                bytes_to_read = bs.file_bytes;

            try
            {
                bytes_read = bs.file.read(bs.buf, 0, bytes_to_read);
                bs.buf_index = 0;
            }
            catch (e)
            {
                // 
                //System.err.println("Big error while reading file: " + e);
                bytes_read = 0;
            }

            if (bytes_read > 0)
            {
                bs.end = bytes_read;
                bs.file_bytes -= bytes_read;
            }
            else
            {
                for (int i = 0; i < Defines.BITSTREAM_BUFFER_SIZE; i++)
                {
                    bs.buf[i] = -1;
                }
                bs.error = 1;
            }
        }
        else
        {
            bs.error = 1;
			for (int i = 0; i < Defines.BITSTREAM_BUFFER_SIZE; i++)
            {
                bs.buf[i] = -1;
            }
        }

        bs.ptr = 0;
        bs.buf_index = 0;

        return bs;
    }
    
    static int zeroFillRightShift(int n, int amount) {
      return (n & 0xffffffff) >> amount;
    }
}