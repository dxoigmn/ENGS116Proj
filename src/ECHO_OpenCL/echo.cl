typedef unsigned char		word8;	
typedef unsigned short		word16;	
typedef unsigned long		word32;
typedef unsigned char BitSequence;
typedef unsigned int DataLength;
typedef enum { 
	SUCCESS=0
	,FAIL=1
	,BAD_HASHBITLEN=2
	,STATE_NULL=3
} HashReturn;


typedef struct {
	word8 tab [4][4][4][4];
	word8 tab_backup [4][4][4][4];
	word8 k1 [4][4];
	word8 k2 [4][4];
	word8 * Addresses[256];
	int index;
	int bit_index;
	int hashbitlen;
	int cv_size;
	int message_size;
	int messlenhi;
	int messlenlo;
	int counter_hi;
	int counter_lo;
	int rounds;
	int Computed;
} hashState;


word8 mul(word8 a, word8 b);
void AddRoundKey(word8 a[4][4], word8 k[4][4]);

HashReturn SetSalt(hashState *state, const BitSequence salt[16]);


int level_trace;

word8 Logtable[256] = {
	0,   0,  25,   1,  50,   2,  26, 198,  75, 199,  27, 104,  51, 238, 223,   3, 
	100,   4, 224,  14,  52, 141, 129, 239,  76, 113,   8, 200, 248, 105,  28, 193, 
	125, 194,  29, 181, 249, 185,  39, 106,  77, 228, 166, 114, 154, 201,   9, 120, 
	101,  47, 138,   5,  33,  15, 225,  36,  18, 240, 130,  69,  53, 147, 218, 142, 
	150, 143, 219, 189,  54, 208, 206, 148,  19,  92, 210, 241,  64,  70, 131,  56, 
	102, 221, 253,  48, 191,   6, 139,  98, 179,  37, 226, 152,  34, 136, 145,  16, 
	126, 110,  72, 195, 163, 182,  30,  66,  58, 107,  40,  84, 250, 133,  61, 186, 
	43, 121,  10,  21, 155, 159,  94, 202,  78, 212, 172, 229, 243, 115, 167,  87, 
	175,  88, 168,  80, 244, 234, 214, 116,  79, 174, 233, 213, 231, 230, 173, 232, 
	44, 215, 117, 122, 235,  22,  11, 245,  89, 203,  95, 176, 156, 169,  81, 160, 
	127,  12, 246, 111,  23, 196,  73, 236, 216,  67,  31,  45, 164, 118, 123, 183, 
	204, 187,  62,  90, 251,  96, 177, 134,  59,  82, 161, 108, 170,  85,  41, 157, 
	151, 178, 135, 144,  97, 190, 220, 252, 188, 149, 207, 205,  55,  63,  91, 209, 
	83,  57, 132,  60,  65, 162, 109,  71,  20,  42, 158,  93,  86, 242, 211, 171, 
	68,  17, 146, 217,  35,  32,  46, 137, 180, 124, 184,  38, 119, 153, 227, 165, 
	103,  74, 237, 222, 197,  49, 254,  24,  13,  99, 140, 128, 192, 247, 112,   7, 
};

word8 Alogtable[256] = {
	1,   3,   5,  15,  17,  51,  85, 255,  26,  46, 114, 150, 161, 248,  19,  53, 
	95, 225,  56,  72, 216, 115, 149, 164, 247,   2,   6,  10,  30,  34, 102, 170, 
	229,  52,  92, 228,  55,  89, 235,  38, 106, 190, 217, 112, 144, 171, 230,  49, 
	83, 245,   4,  12,  20,  60,  68, 204,  79, 209, 104, 184, 211, 110, 178, 205, 
	76, 212, 103, 169, 224,  59,  77, 215,  98, 166, 241,   8,  24,  40, 120, 136, 
	131, 158, 185, 208, 107, 189, 220, 127, 129, 152, 179, 206,  73, 219, 118, 154, 
	181, 196,  87, 249,  16,  48,  80, 240,  11,  29,  39, 105, 187, 214,  97, 163, 
	254,  25,  43, 125, 135, 146, 173, 236,  47, 113, 147, 174, 233,  32,  96, 160, 
	251,  22,  58,  78, 210, 109, 183, 194,  93, 231,  50,  86, 250,  21,  63,  65, 
	195,  94, 226,  61,  71, 201,  64, 192,  91, 237,  44, 116, 156, 191, 218, 117, 
	159, 186, 213, 100, 172, 239,  42, 126, 130, 157, 188, 223, 122, 142, 137, 128, 
	155, 182, 193,  88, 232,  35, 101, 175, 234,  37, 111, 177, 200,  67, 197,  84, 
	252,  31,  33,  99, 165, 244,   7,   9,  27,  45, 119, 153, 176, 203,  70, 202, 
	69, 207,  74, 222, 121, 139, 134, 145, 168, 227,  62,  66, 198,  81, 243,  14, 
	18,  54,  90, 238,  41, 123, 141, 140, 143, 138, 133, 148, 167, 242,  13,  23, 
	57,  75, 221, 124, 132, 151, 162, 253,  28,  36, 108, 180, 199,  82, 246,   1, 
};

word8 S[256] = {
	99, 124, 119, 123, 242, 107, 111, 197,  48,   1, 103,  43, 254, 215, 171, 118, 
	202, 130, 201, 125, 250,  89,  71, 240, 173, 212, 162, 175, 156, 164, 114, 192, 
	183, 253, 147,  38,  54,  63, 247, 204,  52, 165, 229, 241, 113, 216,  49,  21, 
	4, 199,  35, 195,  24, 150,   5, 154,   7,  18, 128, 226, 235,  39, 178, 117, 
	9, 131,  44,  26,  27, 110,  90, 160,  82,  59, 214, 179,  41, 227,  47, 132, 
	83, 209,   0, 237,  32, 252, 177,  91, 106, 203, 190,  57,  74,  76,  88, 207, 
	208, 239, 170, 251,  67,  77,  51, 133,  69, 249,   2, 127,  80,  60, 159, 168, 
	81, 163,  64, 143, 146, 157,  56, 245, 188, 182, 218,  33,  16, 255, 243, 210, 
	205,  12,  19, 236,  95, 151,  68,  23, 196, 167, 126,  61, 100,  93,  25, 115, 
	96, 129,  79, 220,  34,  42, 144, 136,  70, 238, 184,  20, 222,  94,  11, 219, 
	224,  50,  58,  10,  73,   6,  36,  92, 194, 211, 172,  98, 145, 149, 228, 121, 
	231, 200,  55, 109, 141, 213,  78, 169, 108,  86, 244, 234, 101, 122, 174,   8, 
	186, 120,  37,  46,  28, 166, 180, 198, 232, 221, 116,  31,  75, 189, 139, 138, 
	112,  62, 181, 102,  72,   3, 246,  14,  97,  53,  87, 185, 134, 193,  29, 158, 
	225, 248, 152,  17, 105, 217, 142, 148, 155,  30, 135, 233, 206,  85,  40, 223, 
	140, 161, 137,  13, 191, 230,  66, 104,  65, 153,  45,  15, 176,  84, 187,  22, 
};

word8 Sbox[256] = {
	99, 124, 119, 123, 242, 107, 111, 197,  48,   1, 103,  43, 254, 215, 171, 118, 
	202, 130, 201, 125, 250,  89,  71, 240, 173, 212, 162, 175, 156, 164, 114, 192, 
	183, 253, 147,  38,  54,  63, 247, 204,  52, 165, 229, 241, 113, 216,  49,  21, 
	4, 199,  35, 195,  24, 150,   5, 154,   7,  18, 128, 226, 235,  39, 178, 117, 
	9, 131,  44,  26,  27, 110,  90, 160,  82,  59, 214, 179,  41, 227,  47, 132, 
	83, 209,   0, 237,  32, 252, 177,  91, 106, 203, 190,  57,  74,  76,  88, 207, 
	208, 239, 170, 251,  67,  77,  51, 133,  69, 249,   2, 127,  80,  60, 159, 168, 
	81, 163,  64, 143, 146, 157,  56, 245, 188, 182, 218,  33,  16, 255, 243, 210, 
	205,  12,  19, 236,  95, 151,  68,  23, 196, 167, 126,  61, 100,  93,  25, 115, 
	96, 129,  79, 220,  34,  42, 144, 136,  70, 238, 184,  20, 222,  94,  11, 219, 
	224,  50,  58,  10,  73,   6,  36,  92, 194, 211, 172,  98, 145, 149, 228, 121, 
	231, 200,  55, 109, 141, 213,  78, 169, 108,  86, 244, 234, 101, 122, 174,   8, 
	186, 120,  37,  46,  28, 166, 180, 198, 232, 221, 116,  31,  75, 189, 139, 138, 
	112,  62, 181, 102,  72,   3, 246,  14,  97,  53,  87, 185, 134, 193,  29, 158, 
	225, 248, 152,  17, 105, 217, 142, 148, 155,  30, 135, 233, 206,  85,  40, 223, 
	140, 161, 137,  13, 191, 230,  66, 104,  65, 153,  45,  15, 176,  84, 187,  22, 
};



/* Local Function Prototyptes */
void BigSubWords(hashState *state);
void BigShiftRows(hashState *state);
void BigMixColumns(hashState *state);
void BigFinal(hashState *state);
void Pad(hashState *state);
void SubByte(word8 a[4][4]);
void ShiftRows(word8 a[4][4]);
void MixColumns(word8 a[4][4]);
void aes(word8 a[4][4], word8 k[4][4]);
void Mix4bytes(word8 *a, word8 *b, word8 *c, word8 *d);


__kernel int Hash(                                                       
					__global unsigned int *hashbitlen_in,
					__global char* data,                                 
					__global unsigned int *databitlen_in,             
					__global char* hashval,
					__global int *output                                            
){
	int i = get_global_id(0);
	HashReturn S;
	hashState state_real;
	hashState *state = &state_real;
	unsigned int hashbitlen=*hashbitlen_in;
	unsigned int databitlen=*databitlen_in;
	// S = Init(&state, *hashbitlen);
	// HashReturn Init(hashState *state, int hashbitlen)
	{
		int i,j,k,l,m;
	    if (!state)
	    {
	        return STATE_NULL;
	    }
		if((hashbitlen >= 128) && (hashbitlen <= 512))
		{
			state->hashbitlen = hashbitlen;
		} 
		else
		{
			return BAD_HASHBITLEN;
		}
		m = 0;
		for(j=0; j<4; j++) // big col
		{
			for(i=0; i<4; i++) // big row
			{
				for(l=0; l<4; l++) //col
				{
					for(k=0; k<4; k++) // row
					{
						state->tab[i][j][k][l] = 0;
						state->Addresses[m++] = & state->tab[i][j][k][l];
					}
				}
			}
		}

		if(hashbitlen > 256)
		{
			state->cv_size = 1024;
			state->message_size = 1024;
			state->rounds = 10;
		}
		else 
		{
			state->cv_size = 512;
			state->message_size = 1536;
			state->rounds = 8;
		}	
		for (j=0; j<state->cv_size/512; j++) //big col
		{
			for(i=0; i<4; i++) //big row
			{
				state->tab[i][j][0][0] = hashbitlen;
				state->tab[i][j][1][0] = hashbitlen>>8;
			}
		}
		state->index = state->cv_size/8;
		state->bit_index = 0;
		state->messlenhi = 0;
		state->messlenlo = 0;
		//counter low 64 bits
		state->k1[0][0] = 0;
		state->k1[1][0] = 0;
		state->k1[2][0] = 0;
		state->k1[3][0] = 0;
		state->k1[0][1] = 0;
		state->k1[1][1] = 0;
		state->k1[2][1] = 0;
		state->k1[3][1] = 0;
		//counter high 64 bits
		state->k1[0][2] = 0;
		state->k1[1][2] = 0;
		state->k1[2][2] = 0;
		state->k1[3][2] = 0;
		state->k1[0][3] = 0;
		state->k1[1][3] = 0;
		state->k1[2][3] = 0;
		state->k1[3][3] = 0;
		//salt low 64 bits
		state->k2[0][0] = 0;
		state->k2[1][0] = 0;
		state->k2[2][0] = 0;
		state->k2[3][0] = 0;
		state->k2[0][1] = 0;
		state->k2[1][1] = 0;
		state->k2[2][1] = 0;
		state->k2[3][1] = 0;
		//salt high 64 bits
		state->k2[0][2] = 0;
		state->k2[1][2] = 0;
		state->k2[2][2] = 0;
		state->k2[3][2] = 0;
		state->k2[0][3] = 0;
		state->k2[1][3] = 0;
		state->k2[2][3] = 0;
		state->k2[3][3] = 0;
	    state->Computed   = 0;
		S=SUCCESS;
	}
	if(S != SUCCESS) {
		*output= S;
		return S;
	}
	// S = Update(&state, (BitSequence const *)data, *databitlen);
	// HashReturn Update(hashState *state, const BitSequence *data,
	// 				  DataLength databitlen)
	{
		if (!databitlen)
		{
			return SUCCESS;
		}
	    if (!state || !data)
	    {
	        return STATE_NULL;
	    }
		if (state->bit_index)
		{
			return FAIL;
		}
	    if (state->Computed)
	    {
	        return FAIL;
	    }
		while(databitlen)
		{
			//read data byte
			//Push(state, *data++);
			*state->Addresses[state->index++]= *data++;
			if (databitlen>=8)
			{
				databitlen -=8;
				state->messlenlo += 8;
				if (state->messlenlo == 0)
				{
					state->messlenhi ++;
				}
			}
			else
			{
				//length non multiple of 8
				state->bit_index = (int) databitlen;
				state->index--;
				state->messlenlo += (int) databitlen;
				databitlen = 0;
			}


			if (state->index == 256)
			{
				//block completed
				// Compress(state);
				// void Compress(hashState *state)
				{
					int i;
					// Backup(state);
					// void Backup(hashState *state)
					{
						int i,j,k,l;
						for(i=0; i<4; i++)
						{
							for(j=0; j<4; j++)
							{
								for(k=0; k<4; k++)
								{
									for(l=0; l<4; l++)
									{
										state->tab_backup[i][j][k][l] = state->tab[i][j][k][l];
									}
								}
							}
						}
					}
					state->counter_hi = state->messlenhi;
					state->counter_lo = state->messlenlo;
					for (i=0; i<state->rounds; i++)
					{
						// BigSubWords(state);
						// void BigSubWords(hashState *state)
						{
							int i,j;
							state->k1[0][1] = (state->counter_hi >> 0);
							state->k1[1][1] = (state->counter_hi >> 8);
							state->k1[2][1] = (state->counter_hi >> 16);
							state->k1[3][1] = (state->counter_hi >> 24);
							for (j=0; j<4; j++)
							{
								for (i=0; i<4; i++)
								{
									state->k1[0][0] = (state->counter_lo >> 0);
									state->k1[1][0] = (state->counter_lo >> 8);
									state->k1[2][0] = (state->counter_lo >> 16);
									state->k1[3][0] = (state->counter_lo >> 24);
									// aes(state->tab[i][j], state->k1);
									// void aes(word8 a[4][4], word8 k[4][4])
									{
										// SubByte(state->tab[i][j]);
										// void SubByte(word8 a[4][4])
										 int tmpi=i,tmpj=j;
										{
											/* Replace every byte of the input by the byte at that place
											 * in the nonlinear S-box.
											 */
											int i, j;
											for(i = 0; i < 4; i++)
												for(j = 0; j < 4; j++) 
													state->tab[tmpi][tmpj][i][j] = Sbox[state->tab[tmpi][tmpj][i][j]] ;
										}
										// ShiftRows(state->tab[i][j]);
										// void ShiftRows(word8 a[4][4]) 
										{
											/* Row 0 remains unchanged
											 * The other three rows are shifted a variable amount
											 */
											word8 tmp[4];
											int i, j;

											for(i = 1; i < 4; i++) {
												for(j = 0; j < 4; j++) 
													tmp[j] = state->tab[tmpi][tmpj][i][(j + i) % 4];
												for(j = 0; j < 4; j++) state->tab[tmpi][tmpj][i][j] = tmp[j];
											}
										}
										// MixColumns(state->tab[i][j]);
										// void MixColumns(word8 a[4][4]) 
										{
											/* Mix the four bytes of every column in a linear way	 */
											word8 b[4][4];
											int i, j;
											for(j = 0; j < 4; j++)
												for(i = 0; i < 4; i++)
													b[i][j] = mul(2,state->tab[tmpi][tmpj][i][j])
													^ mul(3,state->tab[tmpi][tmpj][(i + 1) % 4][j])
													^ state->tab[tmpi][tmpj][(i + 2) % 4][j]
													^ state->tab[tmpi][tmpj][(i + 3) % 4][j];
											for(i = 0; i < 4; i++)
												for(j = 0; j < 4; j++) state->tab[tmpi][tmpj][i][j] = b[i][j];
										}
										// AddRoundKey(state->tab[i][j],state->k1);
										// void AddRoundKey(word8 a[4][4], word8 k[4][4])
										{
											/* Exor corresponding text input and key input bytes*/
											int i, j;
											for(i = 0; i < 4; i++)
										   		for(j = 0; j < 4; j++) {
													state->tab[tmpi][tmpj][i][j] ^= (state->k1)[i][j];
												}
										}
									}
									// aes(state->tab[i][j], state->k2);
									// void aes(word8 a[4][4], word8 k[4][4])
									{
										// SubByte(state->tab[i][j]);
										// void SubByte(word8 a[4][4])
										int tmpi=i,tmpj=j;
										{
											/* Replace every byte of the input by the byte at that place
											 * in the nonlinear S-box.
											 */
											int i, j;
											for(i = 0; i < 4; i++)
												for(j = 0; j < 4; j++) 
													state->tab[tmpi][tmpj][i][j] = Sbox[state->tab[tmpi][tmpj][i][j]] ;
										}
										// ShiftRows(state->tab[i][j]);
										// void ShiftRows(word8 a[4][4]) 
										{
											/* Row 0 remains unchanged
											 * The other three rows are shifted a variable amount
											 */
											word8 tmp[4];
											int i, j;

											for(i = 1; i < 4; i++) {
												for(j = 0; j < 4; j++) 
													tmp[j] = state->tab[tmpi][tmpj][i][(j + i) % 4];
												for(j = 0; j < 4; j++) state->tab[tmpi][tmpj][i][j] = tmp[j];
											}
										}
										// MixColumns(state->tab[i][j]);
										// void MixColumns(word8 a[4][4]) 
										{
											/* Mix the four bytes of every column in a linear way	 */
											word8 b[4][4];
											int i, j;
											for(j = 0; j < 4; j++)
												for(i = 0; i < 4; i++)
													b[i][j] = mul(2,state->tab[tmpi][tmpj][i][j])
													^ mul(3,state->tab[tmpi][tmpj][(i + 1) % 4][j])
													^ state->tab[tmpi][tmpj][(i + 2) % 4][j]
													^ state->tab[tmpi][tmpj][(i + 3) % 4][j];
											for(i = 0; i < 4; i++)
												for(j = 0; j < 4; j++) state->tab[tmpi][tmpj][i][j] = b[i][j];
										}
										// AddRoundKey(state->tab[i][j],state->k2);
										// void AddRoundKey(word8 a[4][4], word8 k[4][4])
										{
											/* Exor corresponding text input and key input bytes*/
											int i, j;
											for(i = 0; i < 4; i++)
										   		for(j = 0; j < 4; j++) {
													state->tab[tmpi][tmpj][i][j] ^= (state->k2)[i][j];
												}
										}
									}
									state->counter_lo++;
									if (state->counter_lo == 0)
									{
										state->counter_hi++;
										state->k1[0][1] = (state->counter_hi >> 0);
										state->k1[1][1] = (state->counter_hi >> 8);
										state->k1[2][1] = (state->counter_hi >> 16);
										state->k1[3][1] = (state->counter_hi >> 24);
									}
								}
							}
						}
						// BigShiftRows(state);
						// void BigShiftRows(hashState *state)
						{
							word8 tmp[4][4][4];
							int i, j, k, l, m;	
							for(i = 1; i < 4; i++) 
							{
								for(j = 0; j < 4; j++)
								{
									m = (j + i) % 4;
									for(k = 0; k < 4; k++)
									{
										for(l = 0; l < 4; l++)
										{
						     				tmp[j][k][l] = state->tab[i][m][k][l];
										}
									}
								}
								for(j = 0; j < 4; j++) 
								{
									for(k = 0; k < 4; k++)
									{
										for(l = 0; l < 4; l++)
										{
											state->tab[i][j][k][l] = tmp[j][k][l];
										}
									}
								}
							}
						}
						// BigMixColumns(state);
						// void BigMixColumns(hashState *state)
						{
							int i,j,k;
							for(i=0; i<4; i++)
							{
								for(j=0; j<4; j++)
								{
									for(k=0; k<4; k++)
									{
										// Mix4bytes(&state->tab[0][i][j][k],&state->tab[1][i][j][k],&state->tab[2][i][j][k],&state->tab[3][i][j][k]);
										// void Mix4bytes(word8 *a, word8 *b, word8 *c, word8 *d) 
										{
											/* Mix four bytes in a linear way */
											word8 aa, bb, cc, dd;

											aa = mul(2,(state->tab[0][i][j][k]))^mul(3,state->tab[1][i][j][k])^(state->tab[2][i][j][k])^(state->tab[3][i][j][k]);
											bb = mul(2,state->tab[1][i][j][k])^mul(3,state->tab[2][i][j][k])^(state->tab[3][i][j][k])^(state->tab[0][i][j][k]);
											cc = mul(2,state->tab[2][i][j][k])^mul(3,state->tab[3][i][j][k])^(state->tab[0][i][j][k])^(state->tab[1][i][j][k]);
											dd = mul(2,state->tab[3][i][j][k])^mul(3,state->tab[0][i][j][k])^(state->tab[1][i][j][k])^(state->tab[2][i][j][k]);
											state->tab[0][i][j][k] = aa;
											state->tab[1][i][j][k] = bb;
											state->tab[2][i][j][k] = cc;
											state->tab[3][i][j][k] = dd;
										}
									}
								}
							}
						}
					}
					// BigFinal(state);
					// void BigFinal(hashState *state)
					{
						int i,j,k;
						if (state->cv_size == 512)
						{
							for(i=0; i<4; i++)
							{
								for(k=0; k<4; k++)
								{
									for(j=0; j<4; j++)
									{
										state->tab[i][0][j][k] = 
										state->tab_backup[i][0][j][k] ^ 
										state->tab_backup[i][1][j][k] ^ 
										state->tab_backup[i][2][j][k] ^ 
										state->tab_backup[i][3][j][k] ^
										state->tab[i][0][j][k] ^ 
										state->tab[i][1][j][k] ^ 
										state->tab[i][2][j][k] ^ 
										state->tab[i][3][j][k] ;
									}
								}
							}
						}
						else
						{
							for(i=0; i<4; i++)
							{
								for(k=0; k<4; k++)
								{
									for(j=0; j<4; j++)
									{
										state->tab[i][0][j][k] = 
										state->tab_backup[i][0][j][k] ^ 
										state->tab_backup[i][2][j][k] ^
										state->tab[i][0][j][k] ^ 
										state->tab[i][2][j][k];
									}
								}
							}
							for(i=0; i<4; i++)
							{
								for(k=0; k<4; k++)
								{
									for(j=0; j<4; j++)
									{
										state->tab[i][1][j][k] = 
										state->tab_backup[i][1][j][k] ^ 
										state->tab_backup[i][3][j][k] ^
										state->tab[i][1][j][k] ^ 
										state->tab[i][3][j][k];
									}
								}
							}
						}
					}
				}
				state->index = state->cv_size/8;
			}
		}
		S= SUCCESS;
	}
	if(S != SUCCESS){
		*output= S;
		return S;
	}
	// *output= Final(&state,(BitSequence *)hashval);
	// HashReturn Final(hashState *state, BitSequence *hashval)
	{
		int i;
		word8 MASK_AND[8] = 
		{                                                                                                                                                          
			0xFF, 0x80, 0xC0, 0xE0, 0xF0, 0xF8, 0xFC, 0xFE
		};
	    if (!state)
	    {
	        return STATE_NULL;
	    }
	    if (state->Computed)
	    {
			return FAIL;
		}

		// Pad(state);
		// void Pad(hashState *state)
		{
			int nFinalPadding = 0;
			word8 MASK_AND[8] = 
			{
				// =  - (1<<(7-i))
				0x80, 0xC0, 0xE0, 0xF0, 0xF8, 0xFC, 0xFE, 0xFF
			};
			word8 MASK_OR[8] = 
			{
				// = 1 << (7-i)
				0x80, 0x40, 0x20, 0x10, 0x08, 0x04, 0x02, 0x01
			};
			//first bit of padding
			* state->Addresses[state->index] &= MASK_AND[state->bit_index];
			* state->Addresses[state->index] |= MASK_OR[state->bit_index];

			if ((state->index == state->cv_size/8) && (state->bit_index == 0))
			{
				//no message bit in this block
				nFinalPadding = 1;
			}
			state->index ++;
			if (state->index > 256 - 16 - 2)
			{
				//padding with "0"
				while (state->index < 256)
				{
					//Push(state, 0);
			*state->Addresses[state->index++]= 0;
				}
				// Compress(state);
				// void Compress(hashState *state)
				{
					int i;
					// Backup(state);
					// void Backup(hashState *state)
					{
						int i,j,k,l;
						for(i=0; i<4; i++)
						{
							for(j=0; j<4; j++)
							{
								for(k=0; k<4; k++)
								{
									for(l=0; l<4; l++)
									{
										state->tab_backup[i][j][k][l] = state->tab[i][j][k][l];
									}
								}
							}
						}
					}
					state->counter_hi = state->messlenhi;
					state->counter_lo = state->messlenlo;
					for (i=0; i<state->rounds; i++)
					{
						// BigSubWords(state);
						// void BigSubWords(hashState *state)
						{
							int i,j;
							state->k1[0][1] = (state->counter_hi >> 0);
							state->k1[1][1] = (state->counter_hi >> 8);
							state->k1[2][1] = (state->counter_hi >> 16);
							state->k1[3][1] = (state->counter_hi >> 24);
							for (j=0; j<4; j++)
							{
								for (i=0; i<4; i++)
								{
									state->k1[0][0] = (state->counter_lo >> 0);
									state->k1[1][0] = (state->counter_lo >> 8);
									state->k1[2][0] = (state->counter_lo >> 16);
									state->k1[3][0] = (state->counter_lo >> 24);
									aes(state->tab[i][j], state->k1);
									aes(state->tab[i][j], state->k2);
									state->counter_lo++;
									if (state->counter_lo == 0)
									{
										state->counter_hi++;
										state->k1[0][1] = (state->counter_hi >> 0);
										state->k1[1][1] = (state->counter_hi >> 8);
										state->k1[2][1] = (state->counter_hi >> 16);
										state->k1[3][1] = (state->counter_hi >> 24);
									}
								}
							}
						}
						// BigShiftRows(state);
						// void BigShiftRows(hashState *state)
						{
							word8 tmp[4][4][4];
							int i, j, k, l, m;	
							for(i = 1; i < 4; i++) 
							{
								for(j = 0; j < 4; j++)
								{
									m = (j + i) % 4;
									for(k = 0; k < 4; k++)
									{
										for(l = 0; l < 4; l++)
										{
						     				tmp[j][k][l] = state->tab[i][m][k][l];
										}
									}
								}
								for(j = 0; j < 4; j++) 
								{
									for(k = 0; k < 4; k++)
									{
										for(l = 0; l < 4; l++)
										{
											state->tab[i][j][k][l] = tmp[j][k][l];
										}
									}
								}
							}
						}
						// BigMixColumns(state);
						// void BigMixColumns(hashState *state)
						{
							int i,j,k;
							for(i=0; i<4; i++)
							{
								for(j=0; j<4; j++)
								{
									for(k=0; k<4; k++)
									{
										// Mix4bytes(&state->tab[0][i][j][k],&state->tab[1][i][j][k],&state->tab[2][i][j][k],&state->tab[3][i][j][k]);
										// void Mix4bytes(word8 *a, word8 *b, word8 *c, word8 *d) 
										{
											/* Mix four bytes in a linear way */
											word8 aa, bb, cc, dd;

											aa = mul(2,(state->tab[0][i][j][k]))^mul(3,state->tab[1][i][j][k])^(state->tab[2][i][j][k])^(state->tab[3][i][j][k]);
											bb = mul(2,state->tab[1][i][j][k])^mul(3,state->tab[2][i][j][k])^(state->tab[3][i][j][k])^(state->tab[0][i][j][k]);
											cc = mul(2,state->tab[2][i][j][k])^mul(3,state->tab[3][i][j][k])^(state->tab[0][i][j][k])^(state->tab[1][i][j][k]);
											dd = mul(2,state->tab[3][i][j][k])^mul(3,state->tab[0][i][j][k])^(state->tab[1][i][j][k])^(state->tab[2][i][j][k]);
											state->tab[0][i][j][k] = aa;
											state->tab[1][i][j][k] = bb;
											state->tab[2][i][j][k] = cc;
											state->tab[3][i][j][k] = dd;
										}
									}
								}
							}
						}
					}
					// BigFinal(state);
					// void BigFinal(hashState *state)
					{
						int i,j,k;
						if (state->cv_size == 512)
						{
							for(i=0; i<4; i++)
							{
								for(k=0; k<4; k++)
								{
									for(j=0; j<4; j++)
									{
										state->tab[i][0][j][k] = 
										state->tab_backup[i][0][j][k] ^ 
										state->tab_backup[i][1][j][k] ^ 
										state->tab_backup[i][2][j][k] ^ 
										state->tab_backup[i][3][j][k] ^
										state->tab[i][0][j][k] ^ 
										state->tab[i][1][j][k] ^ 
										state->tab[i][2][j][k] ^ 
										state->tab[i][3][j][k] ;
									}
								}
							}
						}
						else
						{
							for(i=0; i<4; i++)
							{
								for(k=0; k<4; k++)
								{
									for(j=0; j<4; j++)
									{
										state->tab[i][0][j][k] = 
										state->tab_backup[i][0][j][k] ^ 
										state->tab_backup[i][2][j][k] ^
										state->tab[i][0][j][k] ^ 
										state->tab[i][2][j][k];
									}
								}
							}
							for(i=0; i<4; i++)
							{
								for(k=0; k<4; k++)
								{
									for(j=0; j<4; j++)
									{
										state->tab[i][1][j][k] = 
										state->tab_backup[i][1][j][k] ^ 
										state->tab_backup[i][3][j][k] ^
										state->tab[i][1][j][k] ^ 
										state->tab[i][3][j][k];
									}
								}
							}
						}
					}
				}
				
				state->index = state->cv_size/8;
				//no message bit in next block
				nFinalPadding = 1;
			}
			//padding last block
			while (state->index < 256 - 16 - 2)
			{
				//Push(state, 0);
			*state->Addresses[state->index++]= 0;
			}
			//HSIZE (2 bytes)
			//Push(state, state->hashbitlen);
			*state->Addresses[state->index++]= state->hashbitlen;
			//Push(state, state->hashbitlen >> 8);
			*state->Addresses[state->index++]= state->hashbitlen >> 8;
			//message length (8 bytes)
			//Push(state, state->messlenlo >> 0);
			*state->Addresses[state->index++]= state->messlenlo >> 0;
			//Push(state, state->messlenlo >> 8);
			*state->Addresses[state->index++]= state->messlenlo >> 8;
			//Push(state, state->messlenlo >> 16);
			*state->Addresses[state->index++]= state->messlenlo >> 16;
			//Push(state, state->messlenlo >> 24);
			*state->Addresses[state->index++]= state->messlenlo >> 24;
			//Push(state, state->messlenhi >> 0);
			*state->Addresses[state->index++]= state->messlenhi >> 0;
			//Push(state, state->messlenhi >> 8);
			*state->Addresses[state->index++]= state->messlenhi >> 8;
			//Push(state, state->messlenhi >> 16);
			*state->Addresses[state->index++]= state->messlenhi >> 16;
			//Push(state, state->messlenhi >> 24);
			*state->Addresses[state->index++]= state->messlenhi >> 24;
			//High 64 bits of counter set to 0
			while (state->index < 256)
			{
				//Push(state, 0);
			*state->Addresses[state->index++]= 0;
			}
			if (nFinalPadding)
			{
				state->messlenhi = 0;
				state->messlenlo = 0;
			}
			// Compress(state);
			// void Compress(hashState *state)
			{
				int i;
				// Backup(state);
				// void Backup(hashState *state)
				{
					int i,j,k,l;
					for(i=0; i<4; i++)
					{
						for(j=0; j<4; j++)
						{
							for(k=0; k<4; k++)
							{
								for(l=0; l<4; l++)
								{
									state->tab_backup[i][j][k][l] = state->tab[i][j][k][l];
								}
							}
						}
					}
				}
				state->counter_hi = state->messlenhi;
				state->counter_lo = state->messlenlo;
				for (i=0; i<state->rounds; i++)
				{
					// BigSubWords(state);
					// void BigSubWords(hashState *state)
					{
						int i,j;
						state->k1[0][1] = (state->counter_hi >> 0);
						state->k1[1][1] = (state->counter_hi >> 8);
						state->k1[2][1] = (state->counter_hi >> 16);
						state->k1[3][1] = (state->counter_hi >> 24);
						for (j=0; j<4; j++)
						{
							for (i=0; i<4; i++)
							{
								state->k1[0][0] = (state->counter_lo >> 0);
								state->k1[1][0] = (state->counter_lo >> 8);
								state->k1[2][0] = (state->counter_lo >> 16);
								state->k1[3][0] = (state->counter_lo >> 24);
								aes(state->tab[i][j], state->k1);
								aes(state->tab[i][j], state->k2);
								state->counter_lo++;
								if (state->counter_lo == 0)
								{
									state->counter_hi++;
									state->k1[0][1] = (state->counter_hi >> 0);
									state->k1[1][1] = (state->counter_hi >> 8);
									state->k1[2][1] = (state->counter_hi >> 16);
									state->k1[3][1] = (state->counter_hi >> 24);
								}
							}
						}
					}
					// BigShiftRows(state);
					// void BigShiftRows(hashState *state)
					{
						word8 tmp[4][4][4];
						int i, j, k, l, m;	
						for(i = 1; i < 4; i++) 
						{
							for(j = 0; j < 4; j++)
							{
								m = (j + i) % 4;
								for(k = 0; k < 4; k++)
								{
									for(l = 0; l < 4; l++)
									{
					     				tmp[j][k][l] = state->tab[i][m][k][l];
									}
								}
							}
							for(j = 0; j < 4; j++) 
							{
								for(k = 0; k < 4; k++)
								{
									for(l = 0; l < 4; l++)
									{
										state->tab[i][j][k][l] = tmp[j][k][l];
									}
								}
							}
						}
					}
					// BigMixColumns(state);
					// void BigMixColumns(hashState *state)
					{
						int i,j,k;
						for(i=0; i<4; i++)
						{
							for(j=0; j<4; j++)
							{
								for(k=0; k<4; k++)
								{
									// Mix4bytes(&state->tab[0][i][j][k],&state->tab[1][i][j][k],&state->tab[2][i][j][k],&state->tab[3][i][j][k]);
									// void Mix4bytes(word8 *a, word8 *b, word8 *c, word8 *d) 
									{
										/* Mix four bytes in a linear way */
										word8 aa, bb, cc, dd;

										aa = mul(2,(state->tab[0][i][j][k]))^mul(3,state->tab[1][i][j][k])^(state->tab[2][i][j][k])^(state->tab[3][i][j][k]);
										bb = mul(2,state->tab[1][i][j][k])^mul(3,state->tab[2][i][j][k])^(state->tab[3][i][j][k])^(state->tab[0][i][j][k]);
										cc = mul(2,state->tab[2][i][j][k])^mul(3,state->tab[3][i][j][k])^(state->tab[0][i][j][k])^(state->tab[1][i][j][k]);
										dd = mul(2,state->tab[3][i][j][k])^mul(3,state->tab[0][i][j][k])^(state->tab[1][i][j][k])^(state->tab[2][i][j][k]);
										state->tab[0][i][j][k] = aa;
										state->tab[1][i][j][k] = bb;
										state->tab[2][i][j][k] = cc;
										state->tab[3][i][j][k] = dd;
									}
								}
							}
						}
					}
				}
				// BigFinal(state);
				// void BigFinal(hashState *state)
				{
					int i,j,k;
					if (state->cv_size == 512)
					{
						for(i=0; i<4; i++)
						{
							for(k=0; k<4; k++)
							{
								for(j=0; j<4; j++)
								{
									state->tab[i][0][j][k] = 
									state->tab_backup[i][0][j][k] ^ 
									state->tab_backup[i][1][j][k] ^ 
									state->tab_backup[i][2][j][k] ^ 
									state->tab_backup[i][3][j][k] ^
									state->tab[i][0][j][k] ^ 
									state->tab[i][1][j][k] ^ 
									state->tab[i][2][j][k] ^ 
									state->tab[i][3][j][k] ;
								}
							}
						}
					}
					else
					{
						for(i=0; i<4; i++)
						{
							for(k=0; k<4; k++)
							{
								for(j=0; j<4; j++)
								{
									state->tab[i][0][j][k] = 
									state->tab_backup[i][0][j][k] ^ 
									state->tab_backup[i][2][j][k] ^
									state->tab[i][0][j][k] ^ 
									state->tab[i][2][j][k];
								}
							}
						}
						for(i=0; i<4; i++)
						{
							for(k=0; k<4; k++)
							{
								for(j=0; j<4; j++)
								{
									state->tab[i][1][j][k] = 
									state->tab_backup[i][1][j][k] ^ 
									state->tab_backup[i][3][j][k] ^
									state->tab[i][1][j][k] ^ 
									state->tab[i][3][j][k];
								}
							}
						}
					}
				}
			}
		}
		/* output truncated hash value */
		state->index = 0;
		for(i=0; i<((state->hashbitlen + 7)/8); i++)
		{
			// hashval[i] =  Pop(state);
			// word8 Pop(hashState *state)
			{
				hashval[i] = * state->Addresses[state->index++];
			}
		}
		//last byte truncation
		hashval[i-1] &= MASK_AND[state->hashbitlen % 8];
		//clean up
		state->index = 0;
		for (i=0; i<256; i++)
		{
			//Push(state, 0);
			*state->Addresses[state->index++]= 0;
		}
		state->Computed = 1;
		S= SUCCESS;
	}
	*output=S;
	return output;                        
}


word8 mul(word8 a, word8 b) {
	/* multiply two elements of GF(2^m)
	 * needed for MixColumn and InvMixColumn
	 */
	if (a && b) return Alogtable[(Logtable[a] + Logtable[b])%255];
	else return 0;
}

void AddRoundKey(word8 a[4][4], word8 k[4][4]) 
{
	/* Exor corresponding text input and key input bytes
	 */
	int i, j;
	
	for(i = 0; i < 4; i++)
   		for(j = 0; j < 4; j++) a[i][j] ^= k[i][j];
}

void ShiftRows(word8 a[4][4]) {
	/* Row 0 remains unchanged
	 * The other three rows are shifted a variable amount
	 */
	word8 tmp[4];
	int i, j;
	
	for(i = 1; i < 4; i++) {
		for(j = 0; j < 4; j++) 
			tmp[j] = a[i][(j + i) % 4];
		for(j = 0; j < 4; j++) a[i][j] = tmp[j];
	}
}

void SubByte(word8 a[4][4]) {
	/* Replace every byte of the input by the byte at that place
	 * in the nonlinear S-box.
	 */
	int i, j;
	
	for(i = 0; i < 4; i++)
		for(j = 0; j < 4; j++) a[i][j] = S[a[i][j]] ;
}

void MixColumns(word8 a[4][4]) {
	/* Mix the four bytes of every column in a linear way	 */
	word8 b[4][4];
	int i, j;
	
	for(j = 0; j < 4; j++)
		for(i = 0; i < 4; i++)
			b[i][j] = mul(2,a[i][j])
			^ mul(3,a[(i + 1) % 4][j])
			^ a[(i + 2) % 4][j]
			^ a[(i + 3) % 4][j];
	for(i = 0; i < 4; i++)
		for(j = 0; j < 4; j++) a[i][j] = b[i][j];
}

									void aes(word8 a[4][4], word8 k[4][4])
									{
										SubByte(a);
										ShiftRows(a);
										MixColumns(a);
										AddRoundKey(a,k);
									}
