using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BurningTransitionEffect : MonoBehaviour
{
    private Material _mat;

    private float _burningTime;

    private void Awake()
    {
        var shader = Shader.Find("Hidden/Burning");
        _mat = new Material(shader);
    }

    private void Update()
    {
        _mat.SetFloat("_BurningTime", _burningTime);
        _burningTime += Time.deltaTime * 0.5f;
        if (_burningTime > 2f)
        {
            _burningTime = 0;
        }
    }

    private void OnRenderImage(RenderTexture src, RenderTexture dst)
    {
        Graphics.Blit(src, dst, _mat);
    }
}
