texture taggingTexture : CUSTOMTEX0;

technique setTaggingTexture
{
    pass P0
    {
        Texture[0] = taggingTexture; 
    }
}
