#include "mex.h"
#include <string.h>
#include <stdbool.h>
#include <math.h>
#include <stdlib.h>

typedef struct
{
	double **img_round; 
	double *m; 
	double *m_p; 
	double *n; 
	double *n_p; 
}LASERLINE;

typedef struct
{
	int *row_mask; 
	int row_mask_end[2]; 
	int *row_max_idx; 
	double *row_max_val; 
	int global_max_idx[2]; 
	double global_max_val; 
}IMG_ROW_PARA;

typedef struct
{
	int *row_mask; 
	int *col_mask; 
	int row_mask_end[2]; 
	int col_mask_end[2]; 
	int *row_max_idx; 
	int *col_max_idx; 
	double *row_max_val; 
	double *col_max_val; 
	int global_max_idx[2]; 
	double global_max_val; 
}IMG_PARA;

typedef struct
{
	double k;
	double k1;
	bool valid;
}GRADIENT;

void** fspace_2d(int row, int col, int length)
{
	// void **mat; 
	void **mat = (void **)mxCalloc(sizeof(void *), row);
	if (mat == NULL)
	{
		mexPrintf("error1\n"); 
		exit(1); 
	}
	for (int i = 0; i < row; i++)
	{
		mat[i] = (void *)mxCalloc(length, col); 
		if (mat[i] == NULL)
		{
			mexPrintf("error2\n");
			exit(1); 
		}
	}
	return(mat); 
}

void ffree_2d(void **mat, int row)
{
	for (int i = 0; i < row; i++)
	{
		mxFree(mat[i]); 
		mat[i] = NULL; 
	}
	mxFree(mat); 
	mat = NULL; 
}

int round_nngt(double input)
{
	if (input - (int)input < 0.5)
	{
		return((int)input); 
	}
	else
	{
		return((int)(input + 1)); 
	}
}

void init_laserline(LASERLINE *laserline, int M, int N)
{
	laserline->img_round = (double **)fspace_2d(M, N, sizeof(double)); 
	laserline->m = (double *)mxCalloc(sizeof(double), M + N); 
	laserline->m_p = laserline->m; 
	laserline->n = (double *)mxCalloc(sizeof(double), M + N); 
	laserline->n_p = laserline->n; 
}

void init_img_rowpara(IMG_ROW_PARA *imgpara, double **img, int M, int N)
{
	imgpara->row_mask = (int *)mxCalloc(sizeof(int), M); 
	imgpara->row_max_idx = (int *)mxCalloc(sizeof(int), M); 
	imgpara->row_max_val = (double *)mxCalloc(sizeof(double), M); 

	imgpara->row_mask_end[0] = M - 1; 
	imgpara->row_mask_end[1] = 0; 
	imgpara->global_max_val = 0; 

	for (int i = 0; i < M; i++)
	{
		for (int j = 0; j < N; j++)
		{
			if (imgpara->row_max_val[i] < img[i][j])
			{
				imgpara->row_max_val[i] = img[i][j]; 
				imgpara->row_max_idx[i] = j; 
			}
		}
		// printf("%f\n", row_max_val[i]);
		if (imgpara->row_max_val[i] > 0)
		{
			// lowest row number
			if (imgpara->row_mask_end[0] > i)
			{
				imgpara->row_mask_end[0] = i; 
			}
			// highest row number
			if (imgpara->row_mask_end[1] < i)
			{
				imgpara->row_mask_end[1] = i; 
			}
			// global max value and index
			if (imgpara->global_max_val < imgpara->row_max_val[i])
			{
				imgpara->global_max_val = imgpara->row_max_val[i]; 
				imgpara->global_max_idx[0] = i; 
				imgpara->global_max_idx[1] = imgpara->row_max_idx[i]; 
			}
		}
	}
}

void init_img_para(IMG_PARA *imgpara, double **img, int M, int N)
{
	imgpara->row_mask = (int *)mxCalloc(sizeof(int), M); 
	imgpara->row_max_idx = (int *)mxCalloc(sizeof(int), M); 
	imgpara->row_max_val = (double *)mxCalloc(sizeof(double), M); 
	imgpara->row_mask_end[0] = M - 1; 
	imgpara->row_mask_end[1] = 0; 

	imgpara->col_mask = (int *)mxCalloc(sizeof(int), N); 
	imgpara->col_max_idx = (int *)mxCalloc(sizeof(int), N); 
	imgpara->col_max_val = (double *)mxCalloc(sizeof(double), N); 
	imgpara->col_mask_end[0] = N - 1; 
	imgpara->col_mask_end[1] = 0; 

	imgpara->global_max_val = 0; 

	for (int i = 0; i < M; i++)
	{	
		imgpara->row_max_idx[i] = -1;
		imgpara->row_max_val[i] = -1;
	}
	for (int j = 0; j < N; j++)
	{	
		imgpara->col_max_idx[j] = -1;
		imgpara->col_max_val[j] = -1;
	}

	for (int i = 0; i < M; i++)
	{
		for (int j = 0; j < N; j++)
		{
			// row max
			if (imgpara->row_max_val[i] < img[i][j])
			{
				imgpara->row_max_val[i] = img[i][j]; 
				imgpara->row_max_idx[i] = j; 
			}
			// col max
			if (imgpara->col_max_val[j] < img[i][j])
			{
				imgpara->col_max_val[j] = img[i][j]; 
				imgpara->col_max_idx[j] = i; 
			}
		}
		// printf("%f\n", row_max_val[i]);
		if (imgpara->row_max_val[i] > 0)
		{
			// min valid row
			if (imgpara->row_mask_end[0] > i)
			{
				imgpara->row_mask_end[0] = i; 
			}
			// max valid row
			if (imgpara->row_mask_end[1] < i)
			{
				imgpara->row_mask_end[1] = i; 
			}
			// global max value and index
			if (imgpara->global_max_val < imgpara->row_max_val[i])
			{
				imgpara->global_max_val = imgpara->row_max_val[i]; 
				imgpara->global_max_idx[0] = i; 
				imgpara->global_max_idx[1] = imgpara->row_max_idx[i]; 
			}
		}
	}

	for (int j = 0; j < N; j++)
	{
		if (imgpara->col_max_val[j] > 0)
		{
			// min valid col
			if (imgpara->col_mask_end[0] > j)
			{
				imgpara->col_mask_end[0] = j; 
			}
			// max valid col
			if (imgpara->col_mask_end[1] < j)
			{
				imgpara->col_mask_end[1] = j; 
			}
		}
	}
}

void process_basic(IMG_ROW_PARA *imgpara, LASERLINE *laserline, double **img, int M, int N)
{
	// threshold of barycenter method
	double th = 0.1; 
	double cur_th; 
	// gradient and its vertical line gradient
	double k, k1; 
	// temp index variable
	int m, n; 
	// graybarycenter
	double sum, weighted_sum; 
	// subpixel index
	double subpxl_i, subpxl_j; 


	for (int i = imgpara->row_mask_end[1]; i >= imgpara->row_mask_end[0]; i--)
	{
		if (imgpara->row_max_val[i] <= 0)
		{
			continue; 
		}

		sum = imgpara->row_max_val[i]; 
		weighted_sum = imgpara->row_max_val[i] * imgpara->row_max_idx[i]; 

		cur_th = th * imgpara->row_max_val[i]; 

		m = i; 
		// towards the left
		n = imgpara->row_max_idx[i] - 1; 
		while (img[m][n] >= cur_th)
		{
			sum += img[m][n]; 
			weighted_sum += n * img[m][n]; 
			n -= 1; 
		}

		// towards the right
		n = imgpara->row_max_idx[i] + 1;
		while (img[m][n] >= cur_th)
		{
			sum += img[m][n]; 
			weighted_sum += n * img[m][n]; 
			n += 1; 
		}
		subpxl_j = weighted_sum / sum; 
		laserline->img_round[i][round_nngt(subpxl_j)] = 1; 
		*laserline->m_p++ = i; 
		*laserline->n_p++ = subpxl_j; 
	}
}

void process_bidrect(IMG_PARA *imgpara, LASERLINE *laserline, double **img, int M, int N)
{
	// threshold of barycenter method
	double th = 0.1; 
	double cur_th; 
	// gradient and its vertical line gradient
	double k, k1; 
	// temp index variable
	int m, n; 
	// graybarycenter
	double sum, weighted_sum; 
	// subpixel index
	double subpxl_i, subpxl_j; 


	for (int i = imgpara->row_mask_end[1]; i >= imgpara->row_mask_end[0]; i--)
	{
		if (imgpara->row_max_val[i] <= 0)
		{
			continue; 
		}

		sum = imgpara->row_max_val[i]; 
		weighted_sum = imgpara->row_max_val[i] * imgpara->row_max_idx[i]; 

		cur_th = th * imgpara->row_max_val[i]; 

		m = i; 
		// towards the left
		n = imgpara->row_max_idx[i] - 1; 
		while (img[m][n] >= cur_th)
		{
			sum += img[m][n]; 
			weighted_sum += n * img[m][n]; 
			n -= 1; 
		}

		// towards the right
		n = imgpara->row_max_idx[i] + 1;
		while (img[m][n] >= cur_th)
		{
			sum += img[m][n]; 
			weighted_sum += n * img[m][n]; 
			n += 1; 
		}
		subpxl_j = weighted_sum / sum; 
		laserline->img_round[i][round_nngt(subpxl_j)] = 1; 
		*laserline->m_p++ = i; 
		*laserline->n_p++ = subpxl_j; 
	}

	for (int j = imgpara->col_mask_end[1]; j >= imgpara->col_mask_end[0]; j--)
	{
		if (imgpara->col_max_val[j] <= 0)
		{
			continue; 
		}

		sum = imgpara->col_max_val[j]; 
		weighted_sum = imgpara->col_max_val[j] * imgpara->col_max_idx[j]; 

		cur_th = th * imgpara->col_max_val[j]; 

		n = j; 
		// towards the upper
		m = imgpara->col_max_idx[j] - 1; 

		while (img[m][n] >= cur_th)
		{
			sum += img[m][n]; 
			weighted_sum += m * img[m][n]; 
			m -= 1; 
		}

		// towards the lower
		m = imgpara->col_max_idx[j] + 1;
		while (img[m][n] >= cur_th)
		{
			sum += img[m][n]; 
			weighted_sum += m * img[m][n]; 
			m += 1; 
		}

		subpxl_i = weighted_sum / sum; 
		laserline->img_round[round_nngt(subpxl_i)][j] = 1; 
		*laserline->m_p++ = subpxl_i; 
		*laserline->n_p++ = j; 
	}

}

// include img index valid check 
// and 
// row or col max value valid check
bool idx_valid(int row_idx, int col_idx, int img_height, int img_width)
{
	if (col_idx < 0 || row_idx < 0 || row_idx > img_height - 1 || col_idx > img_width - 1 )
		return (false);
	else
		return (true);
}

double least_square(int **points, int count)
{
	// least square method
	double k;

	double sum_x = 0;
	double sum_y = 0;
	double sum_x2 = 0;
	double sum_xy = 0;

	for (int i = 0; i < count; i++)
	{
		sum_x += points[0][i];
		sum_y += points[1][i];
		sum_x2 += points[0][i] * points[0][i];
		sum_xy += points[0][i] * points[1][i];
	}

	double k_numerator = count * sum_xy - sum_x * sum_y;
	double k_denominator = count * sum_x2 - sum_x * sum_x;

	if (k_denominator == 0)
		k_denominator = 1e-5;

	k = k_numerator / k_denominator;

	return (k);
}

GRADIENT line_col_fit(IMG_PARA *imgpara, int col_idx, int M, int N)
{
	GRADIENT gradient;

	int row_th = 500;
	int singleside_num = 20;

	int **points = (int **)fspace_2d(2, 2 * singleside_num + 1, sizeof(int)); 
	int count = 0;

	points[0][count] = imgpara->col_max_idx[col_idx];
	points[1][count] = col_idx;
	count += 1;

	// toward left
	for (int j = col_idx - 1; j > col_idx - singleside_num; j--)
	{
		if ( ! idx_valid(imgpara->col_max_idx[j], j, M, N))
			continue;
		if (abs(imgpara->col_max_idx[j] - imgpara->col_max_idx[j + 1]) > row_th)
			break;
		points[0][count] = imgpara->col_max_idx[j];
		points[1][count] = j;
		count += 1;

	}
	// toward right
	for (int j = col_idx + 1; j < col_idx + singleside_num; j++)
	{
		if ( ! idx_valid(imgpara->col_max_idx[j], j, M, N))
			continue;
		if (abs(imgpara->col_max_idx[j] - imgpara->col_max_idx[j - 1]) > row_th)
			break;
		points[0][count] = imgpara->col_max_idx[j];
		points[1][count] = j;
		count += 1;
	}

	// mexPrintf("count: %d\n", count);

	gradient.k = least_square(points, count);
	if (gradient.k < 1e-5)
		gradient.k = 1e-5;
	gradient.k1 = -1 / gradient.k;
	gradient.valid = true;

	ffree_2d(points, 2);

	return (gradient); 
}

GRADIENT line_row_fit(IMG_PARA *imgpara, int row_idx, int M, int N)
{
	GRADIENT gradient;

	int col_th = 500;
	int singleside_num = 20;

	int **points = (int **)fspace_2d(2, 2 * singleside_num + 1, sizeof(int)); 
	int count = 0;

	points[0][count] = row_idx;
	points[1][count] = imgpara->row_max_idx[row_idx];
	count += 1;

	// toward upper
	for (int i = row_idx - 1; i > row_idx - singleside_num; i--)
	{
		if ( ! idx_valid(i, imgpara->row_max_idx[i], M, N))
			continue;
		if (abs(imgpara->row_max_idx[i] - imgpara->row_max_idx[i + 1]) > col_th)
			break;
		points[0][count] = i;
		points[1][count] = imgpara->row_max_idx[i];
		count += 1;

	}
	// toward lower
	for (int i = row_idx + 1; i < row_idx + singleside_num; i++)
	{
		if ( ! idx_valid(i, imgpara->row_max_idx[i], M, N))
			continue;
		if (abs(imgpara->row_max_idx[i] - imgpara->row_max_idx[i - 1]) > col_th)
			break;
		points[0][count] = i;
		points[1][count] = imgpara->row_max_idx[i];
		count += 1;
	}

	gradient.k = least_square(points, count);
	if (gradient.k < 1e-5)
		gradient.k = 1e-5;
	gradient.k1 = -1 / gradient.k;
	gradient.valid = true;

	ffree_2d(points, 2);

	return (gradient); 
}

// //backups
GRADIENT line_col_fit_simple(IMG_PARA *imgpara, int col_idx, int M, int N)
{
	GRADIENT gradient;

	if ( ! idx_valid(imgpara->col_max_idx[col_idx - 10], col_idx - 10, M, N))
	{
		gradient.valid = false;
		return (gradient);
	}
	if ( ! idx_valid(imgpara->col_max_idx[col_idx + 10], col_idx + 10, M, N))
	{
		gradient.valid = false;
		return (gradient);
	}

	double delta_x = imgpara->col_max_idx[col_idx - 10] - imgpara->col_max_idx[col_idx + 10];
	if (delta_x == 0)
	{
		delta_x = 1e-5;
	}
	gradient.k = (-20) / delta_x;
	gradient.k1 = -1 / gradient.k;
	gradient.valid = true;
	return (gradient); 
}

GRADIENT line_row_fit_simple(IMG_PARA *imgpara, int row_idx, int M, int N)
{
	GRADIENT gradient;

	if ( ! idx_valid(row_idx - 10, imgpara->row_max_idx[row_idx - 10], M, N))
	{
		gradient.valid = false;
		return (gradient);
	}
	if ( ! idx_valid(row_idx + 10, imgpara->row_max_idx[row_idx + 10], M, N))
	{
		gradient.valid = false;
		return (gradient);
	}

	gradient.k = (imgpara->row_max_idx[row_idx - 10] - imgpara->row_max_idx[row_idx + 10]) / (-20);
	gradient.k1 = -1 / gradient.k;
	gradient.valid = true;
	return (gradient); 
}

void process_bidrect_vertical(IMG_PARA *imgpara, LASERLINE *laserline, double **img, int M, int N)
{
	// threshold of barycenter method
	double th = 0.1; 
	double cur_th; 
	// gradient and its vertical line gradient
	double k, k1; 
	// temp index variable
	int m, n; 
	// graybarycenter
	double sum, weighted_sum; 
	// subpixel index
	double subpxl_i, subpxl_j; 

	GRADIENT gradient;


	for (int i = imgpara->row_mask_end[1]; i >= imgpara->row_mask_end[0]; i--)
	{
		if (imgpara->row_max_val[i] <= 0)
		{
			continue;
		}

		gradient = line_row_fit(imgpara, i, M, N);

		if ( ! gradient.valid)
		{
			continue;
		}

		// integer col 
		if (gradient.k1 < -1 || gradient.k1 > 1)
		{
			sum = imgpara->row_max_val[i];
			weighted_sum = imgpara->row_max_val[i] * imgpara->row_max_idx[i];

			cur_th = th * imgpara->row_max_val[i];

			m = i; 

			// towards the left
			n = imgpara->row_max_idx[i] - 1; 
			while (idx_valid(m, n, M, N))
			{
				if (img[m][n] < cur_th)
					break;
				sum += img[m][n]; 
				weighted_sum += n * img[m][n]; 
				n -= 1; 
			}

			// towards the right
			n = imgpara->row_max_idx[i] + 1; 
			while (idx_valid(m, n, M, N))
			{
				if (img[m][n] < cur_th)
					break;
				sum += img[m][n]; 
				weighted_sum += n * img[m][n]; 
				n += 1; 
			}

			subpxl_j = weighted_sum / sum; 
			laserline->img_round[i][round_nngt(subpxl_j)] = 1; 
			*laserline->m_p++ = i; 
			*laserline->n_p++ = subpxl_j; 
		}
	}


	for (int j = imgpara->col_mask_end[1]; j >= imgpara->col_mask_end[0]; j--)
	{
		if (imgpara->col_max_val[j] <= 0)
		{
			continue;
		}

		gradient = line_col_fit(imgpara, j, M, N);

		if ( ! gradient.valid)
		{
			continue;
		}

		//integer col 
		if (gradient.k1 >= -1 && gradient.k1 <= 1)
		{
			sum = imgpara->col_max_val[j];
			weighted_sum = imgpara->col_max_val[j] * imgpara->col_max_idx[j];
			cur_th = th * imgpara->col_max_val[j];

			n = j; 

			// towards the upper
			m = imgpara->col_max_idx[j] - 1; 
			while (idx_valid(m, n, M, N))
			{
				if (img[m][n] < cur_th)
					break;
				sum += img[m][n]; 
				weighted_sum += m * img[m][n]; 
				m -= 1;
			}

			// towards the lower
			m = imgpara->col_max_idx[j] + 1;
			while (idx_valid(m, n, M, N))
			{
				if (img[m][n] < cur_th)
					break;
				sum += img[m][n]; 
				weighted_sum += m * img[m][n]; 
				m += 1; 
			}

			subpxl_i = weighted_sum / sum; 
			laserline->img_round[round_nngt(subpxl_i)][j] = 1; 
			*laserline->m_p++ = subpxl_i; 
			*laserline->n_p++ = j; 
		}
	}
}

void process_bidrect_arbitary(IMG_PARA *imgpara, LASERLINE *laserline, double **img, int M, int N)
{
	// threshold of barycenter method
	double th = 0.1; 
	double cur_th; 
	// gradient and its vertical line gradient
	double k, k1; 
	// temp index variable
	int m, n; 
	// graybarycenter
	double sum, weighted_sum; 
	// subpixel index
	double subpxl_i, subpxl_j; 

	GRADIENT gradient;


	for (int i = imgpara->row_mask_end[1]; i >= imgpara->row_mask_end[0]; i--)
	{
		if (imgpara->row_max_val[i] <= 0)
		{
			continue;
		}

		gradient = line_row_fit(imgpara, i, M, N);

		if ( ! gradient.valid)
		{
			continue;
		}

		// integer col 
		if (gradient.k1 < -1 || gradient.k1 > 1)
		{
			sum = imgpara->row_max_val[i];
			weighted_sum = imgpara->row_max_val[i] * imgpara->row_max_idx[i];

			cur_th = th * imgpara->row_max_val[i];

			// towards the left
			n = imgpara->row_max_idx[i] - 1; 
			m = round_nngt((n - imgpara->row_max_idx[i]) / gradient.k1 + i); 
			while (idx_valid(m, n, M, N))
			{
				if (img[m][n] < cur_th)
					break;
				sum += img[m][n]; 
				weighted_sum += n * img[m][n]; 
				n -= 1; 
				m = round_nngt((n - imgpara->row_max_idx[i]) / gradient.k1 + i); 
			}


			// towards the right
			n = imgpara->row_max_idx[i] + 1; 
			m = round_nngt((n - imgpara->row_max_idx[i]) / gradient.k1 + i); 
			while (idx_valid(m, n, M, N))
			{
				if (img[m][n] < cur_th)
					break;
				sum += img[m][n]; 
				weighted_sum += n * img[m][n]; 
				n += 1; 
				m = round_nngt((n - imgpara->row_max_idx[i]) / gradient.k1 + i); 
			}

			subpxl_j = weighted_sum / sum; 
			laserline->img_round[i][round_nngt(subpxl_j)] = 1; 
			*laserline->m_p++ = i; 
			*laserline->n_p++ = subpxl_j; 
		}
	}

	for (int j = imgpara->col_mask_end[1]; j >= imgpara->col_mask_end[0]; j--)
	{
		
		if (imgpara->col_max_val[j] <= 0)
			continue;

		gradient = line_col_fit(imgpara, j, M, N);

		if ( ! gradient.valid)
			continue;

		//integer col 
		if (gradient.k1 >= -1 && gradient.k1 <= 1)
		{
			sum = imgpara->col_max_val[j];
			weighted_sum = imgpara->col_max_val[j] * imgpara->col_max_idx[j];
			cur_th = th * imgpara->col_max_val[j];

			// towards the upper
			m = imgpara->col_max_idx[j] - 1; 
			n = round_nngt(gradient.k1 / (m - imgpara->col_max_idx[j]) + j);
			while (idx_valid(m, n, M, N))
			{
				if (img[m][n] < cur_th)
					break;
				sum += img[m][n]; 
				weighted_sum += m * img[m][n]; 
				m -= 1;
				n = round_nngt(gradient.k1 / (m - imgpara->col_max_idx[j]) + j);
			}

			// towards the lower
			m = imgpara->col_max_idx[j] + 1;
			n = round_nngt(gradient.k1 / (m - imgpara->col_max_idx[j]) + j);
			while (idx_valid(m, n, M, N))
			{
				if (img[m][n] < cur_th)
					break;
				sum += img[m][n]; 
				weighted_sum += m * img[m][n]; 
				m += 1; 
				n = round_nngt(gradient.k1 / (m - imgpara->col_max_idx[j]) + j);
			}


			subpxl_i = weighted_sum / sum; 
			
			laserline->img_round[round_nngt(subpxl_i)][j] = 1; 
			*laserline->m_p++ = subpxl_i; 
			*laserline->n_p++ = j; 
		}
	}
}

void process_bidrect_longitudinal_prior(IMG_PARA *imgpara, LASERLINE *laserline, double **img, int M, int N)
{
	// threshold of barycenter method
	double th = 0.1; 
	double cur_th; 
	// gradient and its vertical line gradient
	double k, k1; 
	// temp index variable
	int m, n; 
	// graybarycenter
	double sum, weighted_sum; 
	// subpixel index
	double subpxl_i, subpxl_j; 

	GRADIENT gradient;

	for (int i = imgpara->row_mask_end[1]; i >= imgpara->row_mask_end[0]; i--)
	{
		if (imgpara->row_max_val[i] <= 0)
		{
			continue;
		}

		gradient = line_row_fit(imgpara, i, M, N);

		if ( ! gradient.valid)
		{
			continue;
		}

		// integer col 
		if (gradient.k1 < -1 || gradient.k1 > 1)
		{
			sum = imgpara->row_max_val[i];
			weighted_sum = imgpara->row_max_val[i] * imgpara->row_max_idx[i];

			cur_th = th * imgpara->row_max_val[i];

			// towards the left
			n = imgpara->row_max_idx[i] - 1; 
			m = round_nngt((n - imgpara->row_max_idx[i]) / gradient.k1 + i); 
			while (idx_valid(m, n, M, N))
			{
				if (img[m][n] < cur_th)
					break;
				sum += img[m][n]; 
				weighted_sum += n * img[m][n]; 
				n -= 1; 
				m = round_nngt((n - imgpara->row_max_idx[i]) / gradient.k1 + i); 
			}


			// towards the right
			n = imgpara->row_max_idx[i] + 1; 
			m = round_nngt((n - imgpara->row_max_idx[i]) / gradient.k1 + i); 
			while (idx_valid(m, n, M, N))
			{
				if (img[m][n] < cur_th)
					break;
				sum += img[m][n]; 
				weighted_sum += n * img[m][n]; 
				n += 1; 
				m = round_nngt((n - imgpara->row_max_idx[i]) / gradient.k1 + i); 
			}

			subpxl_j = weighted_sum / sum; 
			laserline->img_round[i][round_nngt(subpxl_j)] = 1; 
			*laserline->m_p++ = i; 
			*laserline->n_p++ = subpxl_j; 

			imgpara->row_mask[i] = 1;
			imgpara->col_mask[(int)subpxl_j] = 1;
			imgpara->col_mask[(int)subpxl_j + 1] = 1;
		}
	}

	for (int j = imgpara->col_mask_end[1]; j >= imgpara->col_mask_end[0]; j--)
	{
		
		if (imgpara->col_max_val[j] <= 0)
			continue;

		gradient = line_col_fit(imgpara, j, M, N);

		if ( ! gradient.valid)
			continue;

		//integer col 
		if (gradient.k1 >= -1 && gradient.k1 <= 1)
		{
			sum = imgpara->col_max_val[j];
			weighted_sum = imgpara->col_max_val[j] * imgpara->col_max_idx[j];
			cur_th = th * imgpara->col_max_val[j];

			// towards the upper
			m = imgpara->col_max_idx[j] - 1; 
			n = round_nngt(gradient.k1 / (m - imgpara->col_max_idx[j]) + j);
			while (idx_valid(m, n, M, N))
			{
				if (img[m][n] < cur_th)
					break;
				sum += img[m][n]; 
				weighted_sum += m * img[m][n]; 
				m -= 1;
				n = round_nngt(gradient.k1 / (m - imgpara->col_max_idx[j]) + j);
			}

			// towards the lower
			m = imgpara->col_max_idx[j] + 1;
			n = round_nngt(gradient.k1 / (m - imgpara->col_max_idx[j]) + j);
			while (idx_valid(m, n, M, N))
			{
				if (img[m][n] < cur_th)
					break;
				sum += img[m][n]; 
				weighted_sum += m * img[m][n]; 
				m += 1; 
				n = round_nngt(gradient.k1 / (m - imgpara->col_max_idx[j]) + j);
			}

			subpxl_i = weighted_sum / sum; 
			
			laserline->img_round[round_nngt(subpxl_i)][j] = 1; 
			*laserline->m_p++ = subpxl_i; 
			*laserline->n_p++ = j; 

			imgpara->row_mask[(int)subpxl_i] = 1;
			imgpara->row_mask[(int)subpxl_i + 1] = 1;
			imgpara->col_mask[j] = 1;
		}
	}

	for (int i = imgpara->row_mask_end[1] - 10; i >= imgpara->row_mask_end[0] + 10; i--)
	{
		if (imgpara->row_max_val[i] <= 0)
			continue; 
		if (imgpara->row_mask[i] == 1)
			continue; 

		sum = imgpara->row_max_val[i]; 
		weighted_sum = imgpara->row_max_val[i] * imgpara->row_max_idx[i]; 

		cur_th = th * imgpara->row_max_val[i]; 

		m = i; 
		// towards the left
		n = imgpara->row_max_idx[i] - 1; 
		while (img[m][n] >= cur_th)
		{
			sum += img[m][n]; 
			weighted_sum += n * img[m][n]; 
			n -= 1; 
		}

		// towards the right
		n = imgpara->row_max_idx[i] + 1;
		while (img[m][n] >= cur_th)
		{
			sum += img[m][n]; 
			weighted_sum += n * img[m][n]; 
			n += 1; 
		}
		subpxl_j = weighted_sum / sum; 

		if (imgpara->col_mask[(int)subpxl_j] == 1)
			continue; 
		if (imgpara->col_mask[(int)subpxl_j + 1] == 1)
			continue; 

		laserline->img_round[i][round_nngt(subpxl_j)] = 1; 
		*laserline->m_p++ = i; 
		*laserline->n_p++ = subpxl_j; 
	}

	// for (int j = imgpara->col_mask_end[1] - 10; j >= imgpara->col_mask_end[0] + 10; j--)
	// {
	// 	if (imgpara->col_max_val[j] <= 0)
	// 		continue; 
	// 	if (imgpara->col_mask[j] == 1)
	// 		continue; 

	// 	sum = imgpara->col_max_val[j]; 
	// 	weighted_sum = imgpara->col_max_val[j] * imgpara->col_max_idx[j]; 

	// 	cur_th = th * imgpara->col_max_val[j]; 

	// 	n = j; 
	// 	// towards the upper
	// 	m = imgpara->col_max_idx[j] - 1; 

	// 	while (img[m][n] >= cur_th)
	// 	{
	// 		sum += img[m][n]; 
	// 		weighted_sum += m * img[m][n]; 
	// 		m -= 1; 
	// 	}

	// 	// towards the lower
	// 	m = imgpara->col_max_idx[j] + 1;
	// 	while (img[m][n] >= cur_th)
	// 	{
	// 		sum += img[m][n]; 
	// 		weighted_sum += m * img[m][n]; 
	// 		m += 1; 
	// 	}

	// 	subpxl_i = weighted_sum / sum; 

	// 	if (imgpara->row_mask[(int)subpxl_i] == 1)
	// 		continue; 
	// 	if (imgpara->row_mask[(int)subpxl_i + 1] == 1)
	// 		continue; 

	// 	laserline->img_round[round_nngt(subpxl_i)][j] = 1; 
	// 	*laserline->m_p++ = subpxl_i; 
	// 	*laserline->n_p++ = j; 
	// }
}


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	// double a = 0;
	// mexPrintf("%d\n", round_nngt(a));
	double *mexinput; 
	int M, N; 
	mexinput = mxGetPr(prhs[0]); 
	M = mxGetM(prhs[0]); 
	N = mxGetN(prhs[0]); 

	char *buf; 
    size_t buflen; 
    buflen = mxGetN(prhs[1]) + 1; 
    buf = mxMalloc(buflen); 
    mxGetString(prhs[1], buf, (mwSize) buflen); 

	// resize to 2d
	double **img = (double **)fspace_2d(M, N, sizeof(double)); 
	for (int i = 0; i < M; i++)
	{
		for (int j = 0; j < N; j++)
		{
			img[i][j] = mexinput[j * M + i]; 
		}
	}

	// define laserline struct and initial
	LASERLINE laserline; 
	init_laserline(&laserline, M, N); 

	if (strcmp(buf, "basic") == 0)
    {
		//basic mode

		// define img row para struct and initial
		IMG_ROW_PARA imgpara; 
		init_img_rowpara(&imgpara, img, M, N); 
		process_basic(&imgpara, &laserline, img, M, N); 
    }
	else if (strcmp(buf, "bidirect") == 0)
	{
		// bidirect model

		// define img para struct and initial
		IMG_PARA imgpara; 
		init_img_para(&imgpara, img, M, N); 

		process_bidrect(&imgpara, &laserline, img, M, N); 

	}
	else if (strcmp(buf, "bidirect advance 1") == 0)
	{
		IMG_PARA imgpara; 
		init_img_para(&imgpara, img, M, N); 
		process_bidrect_vertical(&imgpara, &laserline, img, M, N); 
	}
	else if (strcmp(buf, "bidirect advance 2") == 0)
	{
		IMG_PARA imgpara; 
		init_img_para(&imgpara, img, M, N); 
		process_bidrect_arbitary(&imgpara, &laserline, img, M, N); 
	}
	else if (strcmp(buf, "bidirect advance 3") == 0)
	{
		IMG_PARA imgpara; 
		init_img_para(&imgpara, img, M, N); 
		process_bidrect_longitudinal_prior(&imgpara, &laserline, img, M, N); 
	}
	

	double *output_img, *output_m, *output_n; 
	int points_num; 
	points_num = laserline.m_p - laserline.m; 
	// mexPrintf("%d\n", points_num);

	// get output array
	plhs[0] = mxCreateDoubleMatrix(M,N,mxREAL); 
	plhs[1] = mxCreateDoubleMatrix(points_num,1,mxREAL); 
	plhs[2] = mxCreateDoubleMatrix(points_num,1,mxREAL); 
	output_img = mxGetPr(plhs[0]); 
	output_m = mxGetPr(plhs[1]); 
	output_n = mxGetPr(plhs[2]); 

	if (points_num > 0)
	{
		for(int i = 0; i < M; i++)
		{
			for(int j = 0; j < N; j++)
			{
				output_img[j * M + i] = laserline.img_round[i][j]; 
			}
		}
		for (int i = 0; i <= points_num; i++)
		{
			output_m[i] = laserline.m[i] + 1; 
			output_n[i] = laserline.n[i] + 1; 
		}
	}


	// mxFree(laserline.m); 
	// mxFree(laserline.n); 
	// ffree_2d(img, M); 
	// ffree_2d(laserline.img_round, M); 

}
