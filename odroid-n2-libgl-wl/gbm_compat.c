#include <gbm.h>
#include <stdio.h>

uint32_t
gbm_bo_get_offset(struct gbm_bo *bo, int plane)
{
	return 0;
}

uint64_t
gbm_bo_get_modifier(struct gbm_bo *bo)
{
	return 0;
	//return DRM_FORMAT_MOD_INVALID;
}

int
gbm_bo_get_plane_count(struct gbm_bo *bo)
{
	return 1;
}

union gbm_bo_handle
gbm_bo_get_handle_for_plane(struct gbm_bo *bo, int plane)
{
	return gbm_bo_get_handle(bo);

}

uint32_t
gbm_bo_get_stride_for_plane(struct gbm_bo *bo, int plane)
{
	return gbm_bo_get_stride(bo);
}

struct gbm_surface *
gbm_surface_create_with_modifiers(struct gbm_device *gbm,
                                  uint32_t width, uint32_t height,
                                  uint32_t format,
                                  const uint64_t *modifiers,
                                  const unsigned int count)
{
	return NULL;
}